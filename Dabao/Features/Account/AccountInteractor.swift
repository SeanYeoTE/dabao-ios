import Foundation

/// Reads the profile and works out the stats. It sends both again when the profile or the history changes.
@MainActor
final class AccountInteractor: NSObject, AccountInteractorInputProtocol {

    weak var output: AccountInteractorOutputProtocol?

    private let profiles: ProfileStore
    private let history: HistoryStore

    init(profiles: ProfileStore, history: HistoryStore) {
        self.profiles = profiles
        self.history = history
        super.init()
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(storeDidChange),
                           name: ProfileStore.didChangeNotification, object: profiles)
        center.addObserver(self, selector: #selector(storeDidChange),
                           name: HistoryStore.didChangeNotification, object: history)
    }

    func load() {
        output?.didLoad(profile: profiles.profile, stats: AccountStats.make(from: history.orders))
    }

    @objc private func storeDidChange() {
        load()
    }
}
