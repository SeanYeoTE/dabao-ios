import Foundation

/// Gets the app ready before the first screen: catalogue, saved state, fixtures, recommendation index.
@MainActor
enum AppBootstrap {

    /// 1. `-dabaoReset` deletes saved state. 2. Load the catalogue. 3. Restore history, profile and cart from disk.
    /// 4. Apply `-dabaoFixture`, which overrides what was restored (and saves). 5. Start the delivery tracker. 6. Build the recommendation index.
    /// Calls `completion` on the main actor once, with the catalogue error if loading failed.
    static func start(completion: @escaping (Error?) -> Void) {
        if LaunchOptions.reset {
            PersistenceController.shared.reset()
        }

        CatalogStore.shared.load { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let restaurants):
                let state = PersistenceController.shared.loadState()
                HistoryStore.shared.replaceAll(state.history)
                ProfileStore.shared.replace(state.profile)
                CartStore.shared.restore(state.cart, catalog: CatalogStore.shared)

                if let fixture = LaunchOptions.fixture {
                    Fixtures.apply(fixture, catalog: CatalogStore.shared)
                }
                DeliveryTracker.shared.start()
                Recommender.shared.prepare(restaurants: restaurants)
                completion(nil)
            }
        }
    }
}
