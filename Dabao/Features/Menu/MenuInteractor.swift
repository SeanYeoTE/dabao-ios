import Foundation

/// The Interactor holds the business rules for this screen.
/// It knows nothing about UIKit, labels or table views.
@MainActor
final class MenuInteractor: MenuInteractorInputProtocol {

    weak var output: MenuInteractorOutputProtocol?

    private let restaurant: Restaurant
    private let cart: CartStore

    init(restaurant: Restaurant, cart: CartStore) {
        self.restaurant = restaurant
        self.cart = cart
    }

    func loadMenu() {
        // Rule: show dishes grouped by category, in the order the categories first appear,
        // and alphabetically within each category.
        let categoryOrder = restaurant.menu.map(\.category).uniqued()
        let sorted = restaurant.menu.sorted { lhs, rhs in
            let lhsIndex = categoryOrder.firstIndex(of: lhs.category) ?? 0
            let rhsIndex = categoryOrder.firstIndex(of: rhs.category) ?? 0
            if lhsIndex != rhsIndex { return lhsIndex < rhsIndex }
            return lhs.name < rhs.name
        }
        output?.didLoadMenu(restaurant: restaurant, items: sorted)
        output?.didUpdateCart(currentSummary())
    }

    func addItem(id: String) {
        guard let item = restaurant.menu.first(where: { $0.id == id }) else { return }

        // Rule: you can't order from a closed restaurant.
        if !restaurant.isOpen {
            output?.didFailToAdd(item, reason: .restaurantClosed)
            return
        }

        // Rule: sold-out dishes can't be added.
        if item.isSoldOut {
            output?.didFailToAdd(item, reason: .soldOut)
            return
        }

        // Rule: a cart can only hold food from one restaurant at a time.
        if let current = cart.restaurant, current.id != restaurant.id, !cart.lines.isEmpty {
            output?.didFailToAdd(item, reason: .cartFromAnotherRestaurant(current.name))
            return
        }

        // Rule: at most `maxQuantityPerItem` of any one dish.
        if cart.quantity(of: item) >= CartStore.maxQuantityPerItem {
            output?.didFailToAdd(item, reason: .limitReached(CartStore.maxQuantityPerItem))
            return
        }

        cart.add(item, from: restaurant)
        output?.didUpdateCart(currentSummary())
    }

    func removeItem(id: String) {
        guard let item = restaurant.menu.first(where: { $0.id == id }) else { return }
        cart.remove(item)
        output?.didUpdateCart(currentSummary())
    }

    private func currentSummary() -> CartSummary {
        // Only count the cart if it's for this restaurant.
        guard cart.restaurant?.id == restaurant.id else {
            return CartSummary(quantities: [:], itemCount: 0, total: 0)
        }
        var quantities: [String: Int] = [:]
        for line in cart.lines {
            quantities[line.item.id] = line.quantity
        }
        return CartSummary(quantities: quantities, itemCount: cart.itemCount, total: cart.subtotal)
    }
}

private extension Array where Element: Hashable {
    /// The elements in order, without duplicates.
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
