import Foundation

/// A cart line as saved to disk. It stores ids only; the catalogue supplies the rest on restore.
nonisolated struct PersistedCartLine: Codable, Sendable {
    let id: UUID
    let restaurantID: String
    let menuItemID: String
    let quantity: Int
    let notes: String
}

/// Everything we save to `state.json`.
nonisolated struct AppState: Codable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var cart: [PersistedCartLine]
    /// Newest first.
    var history: [PastOrder]

    static let empty = AppState(schemaVersion: currentSchemaVersion, cart: [], history: [])
}
