import Foundation

/// Reads the profile being edited and saves the result.
@MainActor
final class AccountEditInteractor: AccountEditInteractorInputProtocol {

    private let profiles: ProfileStore

    init(profiles: ProfileStore) {
        self.profiles = profiles
    }

    var currentProfile: UserProfile? {
        profiles.profile
    }

    func save(_ profile: UserProfile) {
        profiles.update(profile)
    }
}
