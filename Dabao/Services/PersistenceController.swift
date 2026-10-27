import Foundation
import os

/// Saves and restores `AppState` (the cart, order history and profile) as `state.json`.
///
/// Saves are debounced, so a burst of taps writes once. We take the snapshot on the main actor,
/// then encode and write it on a background queue so the UI never waits on the disk.
@MainActor
final class PersistenceController {

    static let shared = PersistenceController()

    /// `Application Support/Dabao/state.json`. The directory is created when we first write.
    let fileURL: URL

    nonisolated private static let logger = Logger(subsystem: "com.tinkercademy.dabao", category: "persistence")
    private static let debounceInterval: Duration = .milliseconds(300)

    /// One serial queue, so writes land in the order they were made.
    private let writeQueue = DispatchQueue(label: "com.tinkercademy.dabao.persistence", qos: .utility)
    private var debounceTask: Task<Void, Never>?

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.fileURL = base.appendingPathComponent("Dabao", isDirectory: true)
                .appendingPathComponent("state.json")
        }
    }

    // MARK: - Loading

    /// Reads the saved state. A missing file is a fresh install. A file we can't read, or one written by a
    /// newer app, is moved aside as `state.corrupt-<unix time>.json` so nothing is lost, and we start empty.
    func loadState() -> AppState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .empty }
        do {
            let data = try Data(contentsOf: fileURL)
            let state = try PersistenceController.decoder().decode(AppState.self, from: data)
            guard state.schemaVersion <= AppState.currentSchemaVersion else {
                throw CocoaError(.coderInvalidValue)
            }
            return state
        } catch {
            PersistenceController.logger.error("Saved state is unreadable: \(String(describing: error), privacy: .public)")
            quarantine()
            return .empty
        }
    }

    // MARK: - Saving

    /// Call after any change to the cart, history or profile. Writes 0.3 s after the last call.
    func scheduleSave() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: PersistenceController.debounceInterval)
            guard !Task.isCancelled else { return }
            debounceTask = nil
            let snapshot = currentState()
            let url = fileURL
            writeQueue.async {
                PersistenceController.write(snapshot, to: url)
            }
        }
    }

    /// Writes any pending change right now and waits for it. Call when the app goes to the background.
    /// Does nothing if there is nothing pending, so it can never overwrite saved state with an empty cart.
    func flush() {
        guard debounceTask != nil else {
            writeQueue.sync {}
            return
        }
        debounceTask?.cancel()
        debounceTask = nil
        let snapshot = currentState()
        let url = fileURL
        writeQueue.sync {
            PersistenceController.write(snapshot, to: url)
        }
    }

    /// Deletes the saved state (the `-dabaoReset` launch option).
    func reset() {
        debounceTask?.cancel()
        debounceTask = nil
        let url = fileURL
        writeQueue.sync {
            do {
                try FileManager.default.removeItem(at: url)
            } catch CocoaError.fileNoSuchFile {
                // Nothing to delete.
            } catch {
                PersistenceController.logger.error("Couldn't delete state: \(String(describing: error), privacy: .public)")
            }
        }
    }

    // MARK: - Helpers

    private func currentState() -> AppState {
        AppState(schemaVersion: AppState.currentSchemaVersion,
                 cart: CartStore.shared.persisted,
                 history: HistoryStore.shared.orders,
                 profile: ProfileStore.shared.profile)
    }

    private func quarantine() {
        let stamp = Int(Date().timeIntervalSince1970)
        let destination = fileURL.deletingLastPathComponent().appendingPathComponent("state.corrupt-\(stamp).json")
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: fileURL, to: destination)
        } catch {
            PersistenceController.logger.error("Couldn't quarantine state: \(String(describing: error), privacy: .public)")
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    nonisolated private static func write(_ state: AppState, to url: URL) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let data = try encoder().encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            logger.error("Couldn't save state: \(String(describing: error), privacy: .public)")
        }
    }

    // Pretty, sorted and ISO 8601, so QA can read state.json with jq.
    nonisolated private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    nonisolated private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
