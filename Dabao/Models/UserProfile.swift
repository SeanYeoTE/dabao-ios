import Foundation

/// The avatar colour. Raw values match `DS.AvatarPalette.names`, so the screens can look the colour up by name.
nonisolated enum AvatarColor: String, Codable, CaseIterable, Sendable {
    case pink, orange, green, blue, purple, teal
}

/// The person using the app. Saved in `state.json`; there's no account server.
nonisolated struct UserProfile: Codable, Hashable, Sendable {
    /// Trimmed, 1 to 40 characters.
    var name: String
    /// Empty, or exactly 8 digits without the +65.
    var phone: String
    /// Empty, or a valid address, trimmed and lowercased.
    var email: String
    /// nil means show the initials instead.
    var avatarEmoji: String?
    var avatarColor: AvatarColor

    /// Up to two uppercase letters: the first letter of each of the first two words.
    var initials: String {
        name.split(whereSeparator: \.isWhitespace)
            .prefix(2)
            .compactMap(\.first)
            .map { String($0).uppercased() }
            .joined()
    }
}
