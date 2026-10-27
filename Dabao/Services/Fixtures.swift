import Foundation
import os

/// Ready-made carts and histories for QA, picked with `-dabaoFixture <name>`.
/// Each one replaces the cart and the history, then saves.
@MainActor
enum Fixtures {

    static let names = ["empty", "cart-chicken-rice", "history-laksa", "history-mixed",
                         "order-on-the-way", "two-active-orders", "profile-sample"]

    /// The person `profile-sample` signs in as.
    static let sampleProfile = UserProfile(name: "Aisha Tan", phone: "91234567", email: "aisha@example.com",
                                           avatarEmoji: "🍜", avatarColor: .teal)

    private static let logger = Logger(subsystem: "com.tinkercademy.dabao", category: "fixtures")

    /// Applies the named fixture. An unknown name is logged and ignored.
    static func apply(_ name: String, catalog: CatalogStore, cart: CartStore = .shared,
                      history: HistoryStore = .shared, profiles: ProfileStore = .shared, now: Date = Date()) {
        switch name {
        case "empty":
            profiles.replace(nil)
            install(spec: [], orders: [], cart: cart, history: history)
        case "cart-chicken-rice":
            install(spec: [(id: "r1", items: [("r1m1", 2), ("r1m5", 1)])], orders: [],
                    catalog: catalog, cart: cart, history: history)
        case "history-laksa":
            guard let stall = firstRestaurant(in: catalog, where: { $0.tags.contains("laksa") }),
                  let dish = laksaDish(of: stall) else { return missing(name) }
            let orders = [(1, 1), (2, 2), (3, 1)].map { days, quantity in
                order(from: stall, lines: [(dish, quantity)], placedAt: daysAgo(days, from: now))
            }
            install(spec: [], orders: orders, cart: cart, history: history)
        case "history-mixed":
            guard let orders = historyMixed(catalog: catalog, now: now) else { return missing(name) }
            install(spec: [], orders: orders, cart: cart, history: history)
        case "profile-sample":
            guard let orders = historyMixed(catalog: catalog, now: now) else { return missing(name) }
            profiles.replace(sampleProfile)
            install(spec: [], orders: orders, cart: cart, history: history)
        case "order-on-the-way", "two-active-orders":
            guard let rice = catalog.restaurant(id: "r1"), let riceDish = item("r1m1", in: rice)
            else { return missing(name) }
            var orders = historyMixed(catalog: catalog, now: now) ?? []
            orders.append(order(from: rice, lines: [(riceDish, 1)], placedAt: placed(rice, progress: 0.5, now: now)))
            if name == "order-on-the-way" {
                install(spec: [], orders: orders, cart: cart, history: history)
            } else {
                guard let kopi = catalog.restaurant(id: "r3"), let kopiDish = kopi.menu.first(where: { !$0.isSoldOut }),
                      let mala = catalog.restaurant(id: "r2"), let malaDish = mala.menu.first(where: { !$0.isSoldOut })
                else { return missing(name) }
                orders.append(order(from: kopi, lines: [(kopiDish, 1)], placedAt: placed(kopi, progress: 0.2, now: now)))
                install(spec: [(id: mala.id, items: [(malaDish.id, 1)])], orders: orders,
                        catalog: catalog, cart: cart, history: history)
            }
        default:
            logger.error("Unknown fixture \(name, privacy: .public)")
        }
    }

    // MARK: - Helpers

    /// Four single-item orders from four restaurants, newest first: laksa, chicken rice, Indian, mala.
    private static func historyMixed(catalog: CatalogStore, now: Date) -> [PastOrder]? {
        guard let laksa = firstRestaurant(in: catalog, where: { $0.tags.contains("laksa") }),
              let laksaDish = laksaDish(of: laksa),
              let rice = catalog.restaurant(id: "r1"), let riceDish = item("r1m1", in: rice),
              let indian = firstRestaurant(in: catalog, where: { $0.cuisine == "Indian" }),
              let curry = indian.menu.first(where: { !$0.isSoldOut }),
              let mala = catalog.restaurant(id: "r2"), let malaDish = item("r2m1", in: mala)
        else { return nil }
        return [
            order(from: laksa, lines: [(laksaDish, 1)], placedAt: daysAgo(1, from: now)),
            order(from: rice, lines: [(riceDish, 1)], placedAt: daysAgo(2, from: now)),
            order(from: indian, lines: [(curry, 1)], placedAt: daysAgo(3, from: now)),
            order(from: mala, lines: [(malaDish, 1)], placedAt: daysAgo(4, from: now)),
        ]
    }

    /// A placement time that puts the order at `progress` of its delivery right now.
    private static func placed(_ restaurant: Restaurant, progress: Double, now: Date) -> Date {
        let total = Double(restaurant.deliveryMinutes) * DeliveryTracker.shared.minuteLength
        return now.addingTimeInterval(-total * progress)
    }

    private static func install(spec: [(id: String, items: [(String, Int)])], orders: [PastOrder],
                                catalog: CatalogStore? = nil, cart: CartStore, history: HistoryStore) {
        cart.clear()
        if let catalog, let first = spec.first, let restaurant = catalog.restaurant(id: first.id) {
            for (itemID, quantity) in first.items {
                guard let menuItem = item(itemID, in: restaurant) else { continue }
                for _ in 0..<quantity {
                    _ = cart.tryAdd(menuItem, from: restaurant)
                }
            }
        }
        history.replaceAll(orders)
        PersistenceController.shared.scheduleSave()
    }

    private static func missing(_ name: String) {
        logger.error("Fixture \(name, privacy: .public) needs restaurants the catalogue doesn't have")
    }

    private static func firstRestaurant(in catalog: CatalogStore, where matches: (Restaurant) -> Bool) -> Restaurant? {
        catalog.restaurants.first(where: matches)
    }

    private static func laksaDish(of restaurant: Restaurant) -> MenuItem? {
        restaurant.menu.first(where: { $0.tags.contains("laksa") })
    }

    private static func item(_ id: String, in restaurant: Restaurant) -> MenuItem? {
        restaurant.menu.first(where: { $0.id == id })
    }

    private static func daysAgo(_ days: Int, from now: Date) -> Date {
        now.addingTimeInterval(-Double(days) * 24 * 60 * 60)
    }

    private static func order(from restaurant: Restaurant, lines: [(MenuItem, Int)], placedAt: Date) -> PastOrder {
        let pastLines = lines.map { menuItem, quantity in
            PastOrderLine(id: UUID(), menuItemID: menuItem.id, name: menuItem.name,
                          unitPrice: menuItem.price, quantity: quantity, notes: "")
        }
        let subtotal = pastLines.reduce(Decimal(0)) { $0 + $1.subtotal }
        return PastOrder(id: UUID(), placedAt: placedAt, restaurantID: restaurant.id,
                         restaurantName: restaurant.name, cuisine: restaurant.cuisine,
                         imageName: restaurant.imageName, colorHex: restaurant.colorHex, lines: pastLines,
                         subtotal: subtotal, deliveryFee: restaurant.deliveryFee,
                         total: subtotal + restaurant.deliveryFee,
                         deliveryMinutes: restaurant.deliveryMinutes,
                         restaurantArea: restaurant.area)
    }
}
