import Foundation
import os

/// Anything that can give us restaurants. The real app talks to a server;
/// ours reads a JSON file bundled with the app, so it works offline in class.
protocol RestaurantServicing {
    func fetchRestaurants(completion: @escaping (Result<[Restaurant], Error>) -> Void)
}

/// The restaurant catalogue. It reads the bundled `restaurants.json` once and keeps it in memory,
/// so every screen sees the same restaurants.
@MainActor
final class CatalogStore: RestaurantServicing {

    static let shared = CatalogStore()

    enum CatalogError: Error {
        case fileNotFound
        case invalid(String)
    }

    private static let logger = Logger(subsystem: "com.tinkercademy.dabao", category: "catalog")

    /// In catalogue order. Empty until loaded.
    private(set) var restaurants: [Restaurant] = []

    private var searchText: [String: String] = [:]
    private var byID: [String: Restaurant] = [:]
    private var pending: [(Result<[Restaurant], Error>) -> Void] = []
    private var isLoading = false

    var isLoaded: Bool { !restaurants.isEmpty }

    /// Unique cuisines, A to Z.
    var cuisines: [String] {
        Array(Set(restaurants.map(\.cuisine))).sorted()
    }

    /// Reads and checks the catalogue off the main thread, then calls back on main. Later calls use the cache.
    func load(bundle: Bundle = .main, completion: @escaping (Result<[Restaurant], Error>) -> Void) {
        if isLoaded {
            completion(.success(restaurants))
            return
        }
        pending.append(completion)
        guard !isLoading else { return }
        isLoading = true

        let url = bundle.url(forResource: "restaurants", withExtension: "json")
        let delay = LaunchOptions.noDelay ? 0 : 0.4

        Task {
            // Pretend we're on a slow network, so we can see loading states.
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            let result = await Task.detached(priority: .userInitiated) {
                CatalogStore.readAndValidate(url: url)
            }.value
            finishLoading(result)
        }
    }

    func fetchRestaurants(completion: @escaping (Result<[Restaurant], Error>) -> Void) {
        load(completion: completion)
    }

    /// Filters by cuisine and a search query, keeping catalogue order.
    /// The query ignores case and accents; every word must match something about the restaurant.
    func restaurants(cuisine: String?, query: String) -> [Restaurant] {
        let words = CatalogStore.fold(query).split(whereSeparator: \.isWhitespace).map(String.init)
        return restaurants.filter { restaurant in
            if let cuisine, restaurant.cuisine != cuisine { return false }
            guard !words.isEmpty else { return true }
            let haystack = searchText[restaurant.id] ?? ""
            return words.allSatisfy { haystack.contains($0) }
        }
    }

    func restaurant(id: String) -> Restaurant? {
        byID[id]
    }

    // MARK: - Loading

    private func finishLoading(_ result: Result<[Restaurant], Error>) {
        isLoading = false
        if case .success(let loaded) = result {
            restaurants = loaded
            byID = Dictionary(loaded.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            searchText = Dictionary(loaded.map { ($0.id, CatalogStore.searchableText(for: $0)) },
                                    uniquingKeysWith: { first, _ in first })
            CatalogStore.logger.info("Loaded \(loaded.count) restaurants")
        } else if case .failure(let error) = result {
            CatalogStore.logger.error("Catalogue failed to load: \(String(describing: error), privacy: .public)")
        }
        let callbacks = pending
        pending = []
        for callback in callbacks {
            callback(result)
        }
    }

    nonisolated private static func readAndValidate(url: URL?) -> Result<[Restaurant], Error> {
        guard let url else { return .failure(CatalogError.fileNotFound) }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Restaurant].self, from: data)
            try validate(decoded)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }

    nonisolated private static func validate(_ restaurants: [Restaurant]) throws {
        var restaurantIDs = Set<String>()
        var itemIDs = Set<String>()
        for restaurant in restaurants {
            guard restaurantIDs.insert(restaurant.id).inserted else {
                throw CatalogError.invalid("Duplicate restaurant id \(restaurant.id)")
            }
            guard !restaurant.menu.isEmpty else {
                throw CatalogError.invalid("Restaurant \(restaurant.id) has no menu items")
            }
            for item in restaurant.menu {
                guard itemIDs.insert(item.id).inserted else {
                    throw CatalogError.invalid("Duplicate item id \(item.id)")
                }
                guard item.price > 0 else {
                    throw CatalogError.invalid("Item \(item.id) has a price of zero or less")
                }
            }
        }
    }

    // MARK: - Search

    nonisolated private static func fold(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    nonisolated private static func searchableText(for restaurant: Restaurant) -> String {
        var parts = [restaurant.name, restaurant.cuisine, restaurant.area]
        parts.append(contentsOf: restaurant.tags)
        for item in restaurant.menu {
            parts.append(item.name)
            parts.append(contentsOf: item.tags)
        }
        return parts.map(fold).joined(separator: "\n")
    }
}
