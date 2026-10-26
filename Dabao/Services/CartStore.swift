import Foundation
import os

/// Holds what's in the cart. One shared cart for the whole app.
///
/// Screens that care about the cart (the Menu and the Cart tab) listen for
/// `CartStore.didChangeNotification` so they can refresh.
@MainActor
final class CartStore {

    static let shared = CartStore()
    static let didChangeNotification = Notification.Name("CartStoreDidChange")

    /// The most of any one dish we let someone order.
    static let maxQuantityPerItem = 10

    /// The longest note we keep on a line.
    static let maxNotesLength = 140

    /// What happened when we tried to add a dish.
    enum AddResult: Equatable {
        case added
        case restaurantClosed
        case soldOut
        case limitReached(Int)
        case differentRestaurant(currentName: String)
    }

    private static let logger = Logger(subsystem: "com.tinkercademy.dabao", category: "cart")

    private(set) var restaurant: Restaurant?
    private(set) var lines: [CartLine] = []

    var itemCount: Int {
        lines.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Decimal {
        lines.reduce(0) { $0 + $1.subtotal }
    }

    var deliveryFee: Decimal {
        restaurant?.deliveryFee ?? 0
    }

    var total: Decimal {
        subtotal + deliveryFee
    }

    /// The cart as ids only, ready to save.
    var persisted: [PersistedCartLine] {
        guard let restaurant else { return [] }
        return lines.map {
            PersistedCartLine(id: $0.id, restaurantID: restaurant.id, menuItemID: $0.item.id,
                              quantity: $0.quantity, notes: $0.notes)
        }
    }

    func quantity(of item: MenuItem) -> Int {
        lines.first(where: { $0.item.id == item.id })?.quantity ?? 0
    }

    func line(id: UUID) -> CartLine? {
        lines.first(where: { $0.id == id })
    }

    // MARK: - Adding

    /// Adds one of `item`. Returns false if we couldn't (sold out, or at the limit).
    /// Legacy: it silently replaces a cart from another restaurant. New UI uses `tryAdd`.
    @discardableResult
    func add(_ item: MenuItem, from restaurant: Restaurant) -> Bool {
        guard !item.isSoldOut else { return false }

        // A cart can only hold food from one restaurant at a time.
        if self.restaurant?.id != restaurant.id {
            lines.removeAll()
            self.restaurant = restaurant
        }
        guard appendOne(item) else {
            notifyChange()
            return false
        }
        notifyChange()
        return true
    }

    /// Adds one of `item` without ever touching another restaurant's cart.
    func tryAdd(_ item: MenuItem, from restaurant: Restaurant) -> AddResult {
        if let reason = blockingReason(for: item, from: restaurant) {
            return reason
        }
        if let current = self.restaurant, current.id != restaurant.id, !lines.isEmpty {
            return .differentRestaurant(currentName: current.name)
        }
        if self.restaurant == nil {
            self.restaurant = restaurant
        }
        guard appendOne(item) else {
            return .limitReached(CartStore.maxQuantityPerItem)
        }
        notifyChange()
        return .added
    }

    /// Empties the cart, then adds one of `item` (still respecting open and sold out).
    func replaceCart(with item: MenuItem, from restaurant: Restaurant) {
        lines.removeAll()
        self.restaurant = nil
        if blockingReason(for: item, from: restaurant) == nil {
            self.restaurant = restaurant
            _ = appendOne(item)
        }
        notifyChange()
    }

    // MARK: - Changing and removing

    func remove(_ item: MenuItem) {
        guard let index = lines.firstIndex(where: { $0.item.id == item.id }) else { return }
        lines[index].quantity -= 1
        if lines[index].quantity == 0 {
            lines.remove(at: index)
        }
        finishRemoval()
    }

    func removeLine(at index: Int) {
        guard lines.indices.contains(index) else { return }
        lines.remove(at: index)
        finishRemoval()
    }

    func removeLine(id: UUID) {
        guard let index = lines.firstIndex(where: { $0.id == id }) else { return }
        removeLine(at: index)
    }

    /// Sets a line's quantity, clamped to 0...max. Zero removes the line.
    func setQuantity(lineID: UUID, to quantity: Int) {
        guard let index = lines.firstIndex(where: { $0.id == lineID }) else { return }
        let clamped = min(max(quantity, 0), CartStore.maxQuantityPerItem)
        if clamped == 0 {
            lines.remove(at: index)
            finishRemoval()
        } else {
            lines[index].quantity = clamped
            notifyChange()
        }
    }

    func setNotes(lineID: UUID, to notes: String) {
        guard let index = lines.firstIndex(where: { $0.id == lineID }) else { return }
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        lines[index].notes = String(trimmed.prefix(CartStore.maxNotesLength))
        notifyChange()
    }

    func clear() {
        lines.removeAll()
        restaurant = nil
        notifyChange()
    }

    // MARK: - Restoring

    /// Rebuilds the cart from saved ids. Anything the catalogue no longer knows is dropped. Doesn't save.
    func restore(_ saved: [PersistedCartLine], catalog: CatalogStore) {
        var restored: [CartLine] = []
        var cartRestaurant: Restaurant?

        for entry in saved {
            guard let owner = catalog.restaurant(id: entry.restaurantID),
                  let item = owner.menu.first(where: { $0.id == entry.menuItemID }) else {
                CartStore.logger.info("Dropped saved cart line for unknown item \(entry.menuItemID, privacy: .public)")
                continue
            }
            // One restaurant per cart: the first valid line decides which.
            if let current = cartRestaurant, current.id != owner.id {
                CartStore.logger.info("Dropped saved cart line from another restaurant \(owner.id, privacy: .public)")
                continue
            }
            guard !restored.contains(where: { $0.item.id == item.id }) else { continue }
            cartRestaurant = owner
            let quantity = min(max(entry.quantity, 1), CartStore.maxQuantityPerItem)
            let notes = String(entry.notes.prefix(CartStore.maxNotesLength))
            restored.append(CartLine(id: entry.id, item: item, quantity: quantity, notes: notes))
        }

        lines = restored
        restaurant = restored.isEmpty ? nil : cartRestaurant
        notifyChange(save: false)
    }

    // MARK: - Helpers

    private func blockingReason(for item: MenuItem, from restaurant: Restaurant) -> AddResult? {
        if !restaurant.isOpen { return .restaurantClosed }
        if item.isSoldOut { return .soldOut }
        return nil
    }

    /// Adds one to an existing line or starts a new one. False if the line is at the limit.
    private func appendOne(_ item: MenuItem) -> Bool {
        if let index = lines.firstIndex(where: { $0.item.id == item.id }) {
            guard lines[index].quantity < CartStore.maxQuantityPerItem else { return false }
            lines[index].quantity += 1
        } else {
            lines.append(CartLine(item: item, quantity: 1))
        }
        return true
    }

    private func finishRemoval() {
        if lines.isEmpty {
            restaurant = nil
        }
        notifyChange()
    }

    private func notifyChange(save: Bool = true) {
        NotificationCenter.default.post(name: CartStore.didChangeNotification, object: self)
        if save {
            PersistenceController.shared.scheduleSave()
        }
    }
}
