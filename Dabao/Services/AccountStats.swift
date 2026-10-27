import Foundation

/// The numbers on the Account page, worked out from the order history.
nonisolated struct AccountStats: Equatable, Sendable {
    let orderCount: Int
    let totalSpent: Decimal
    /// nil when there are no orders.
    let favouriteRestaurantName: String?
    let favouriteRestaurantOrderCount: Int
    /// When the oldest order was placed.
    let firstOrderDate: Date?

    /// The favourite is the restaurant with the most orders (not items). A tie goes to the one ordered from most recently.
    static func make(from orders: [PastOrder]) -> AccountStats {
        let total = orders.reduce(Decimal(0)) { $0 + $1.total }
        let favourite = Dictionary(grouping: orders, by: \.restaurantID)
            .values
            .compactMap { group -> (count: Int, latest: PastOrder)? in
                guard let latest = group.max(by: { $0.placedAt < $1.placedAt }) else { return nil }
                return (group.count, latest)
            }
            .max { lhs, rhs in
                lhs.count != rhs.count ? lhs.count < rhs.count : lhs.latest.placedAt < rhs.latest.placedAt
            }
        return AccountStats(orderCount: orders.count,
                            totalSpent: total,
                            favouriteRestaurantName: favourite?.latest.restaurantName,
                            favouriteRestaurantOrderCount: favourite?.count ?? 0,
                            firstOrderDate: orders.map(\.placedAt).min())
    }
}
