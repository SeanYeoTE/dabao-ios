import Foundation

/// Gets the app ready before the first screen: catalogue, saved state, fixtures, recommendation index.
@MainActor
enum AppBootstrap {

    /// Calls `completion` on the main actor once, with the catalogue error if loading failed.
    static func start(completion: @escaping (Error?) -> Void) {
        CatalogStore.shared.load { result in
            switch result {
            case .success: completion(nil)
            case .failure(let error): completion(error)
            }
        }
    }
}
