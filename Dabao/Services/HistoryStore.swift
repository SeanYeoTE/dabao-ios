import Foundation

/// The orders this person has placed, newest first. One shared list for the whole app.
@MainActor
final class HistoryStore {

    static let shared = HistoryStore()
    static let didChangeNotification = Notification.Name("HistoryStoreDidChange")

    /// Newest first.
    private(set) var orders: [PastOrder] = []

    /// Turns the cart into an order, then empties the cart. Returns nil if the cart is empty.
    @discardableResult
    func place(cart: CartStore, now: Date = Date()) -> PastOrder? {
        guard let restaurant = cart.restaurant, !cart.lines.isEmpty else { return nil }

        // Copy everything the receipt needs, so it never depends on the catalogue.
        let lines = cart.lines.map {
            PastOrderLine(id: UUID(), menuItemID: $0.item.id, name: $0.item.name,
                          unitPrice: $0.item.price, quantity: $0.quantity, notes: $0.notes)
        }
        let order = PastOrder(id: UUID(), placedAt: now,
                              restaurantID: restaurant.id, restaurantName: restaurant.name,
                              cuisine: restaurant.cuisine, imageName: restaurant.imageName,
                              colorHex: restaurant.colorHex, lines: lines,
                              subtotal: cart.subtotal, deliveryFee: cart.deliveryFee, total: cart.total,
                              deliveryMinutes: restaurant.deliveryMinutes)

        orders.insert(order, at: 0)
        notifyChange()
        cart.clear()
        PersistenceController.shared.scheduleSave()
        return order
    }

    func order(id: UUID) -> PastOrder? {
        orders.first(where: { $0.id == id })
    }

    /// Replaces the whole list (restoring from disk, or loading a fixture). Sorts newest first. Doesn't save.
    func replaceAll(_ newOrders: [PastOrder]) {
        orders = newOrders.sorted { $0.placedAt > $1.placedAt }
        notifyChange()
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: HistoryStore.didChangeNotification, object: self)
    }
}
