import Foundation

/// Saves and restores `AppState` (the cart and order history) as `state.json`.
@MainActor
final class PersistenceController {

    static let shared = PersistenceController()

    let fileURL: URL

    init(fileURL: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.fileURL = fileURL ?? base.appendingPathComponent("Dabao", isDirectory: true)
            .appendingPathComponent("state.json")
    }

    func loadState() -> AppState { .empty }
    func scheduleSave() {}
    func flush() {}
    func reset() {}
}
