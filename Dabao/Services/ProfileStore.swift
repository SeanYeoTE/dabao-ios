import Foundation

/// The person's profile, or nil before they add their details. One shared value for the whole app.
@MainActor
final class ProfileStore {

    static let shared = ProfileStore()
    static let didChangeNotification = Notification.Name("ProfileStoreDidChange")

    private(set) var profile: UserProfile?

    /// Saves an edit. Tidies the fields first, so what's on disk is always in one shape.
    func update(_ profile: UserProfile) {
        var tidy = profile
        tidy.name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        tidy.phone = ProfileValidator.normalisedPhone(profile.phone)
        tidy.email = profile.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.profile = tidy
        notifyChange()
        PersistenceController.shared.scheduleSave()
    }

    /// Replaces the profile when restoring from disk or loading a fixture. Doesn't save.
    func replace(_ profile: UserProfile?) {
        self.profile = profile
        notifyChange()
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: ProfileStore.didChangeNotification, object: self)
    }
}
