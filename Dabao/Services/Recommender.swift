import Foundation

/// Suggests restaurants from what someone has ordered before.
@MainActor
final class Recommender {

    static let shared = Recommender()
    static let didUpdateNotification = Notification.Name("RecommenderDidUpdate")

    private(set) var isReady = false
    private var restaurants: [Restaurant] = []

    func prepare(restaurants: [Restaurant]) {
        self.restaurants = restaurants
    }

    func recommendations(history: [PastOrder], limit: Int = 10) -> [Recommendation] {
        let source = restaurants.isEmpty ? CatalogStore.shared.restaurants : restaurants
        let ranked = source.filter(\.isOpen).map {
            Recommendation(restaurantID: $0.id,
                           score: $0.rating * log(1 + Double($0.reviewCount)),
                           reason: "Popular on Dabao")
        }
        return Array(ranked.sorted { $0.score > $1.score }.prefix(limit))
    }

    nonisolated static func tokenize(_ text: String) -> [String] {
        text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    }
}
