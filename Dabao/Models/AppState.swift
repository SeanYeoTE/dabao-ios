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
    /// 2 added `profile`. Version 1 files have no `profile` key, which decodes as nil.
    static let currentSchemaVersion = 2

    var schemaVersion: Int
    var cart: [PersistedCartLine]
    /// Newest first.
    var history: [PastOrder]
    /// nil until the person adds their details.
    var profile: UserProfile? = nil

    static let empty = AppState(schemaVersion: currentSchemaVersion, cart: [], history: [])
}
