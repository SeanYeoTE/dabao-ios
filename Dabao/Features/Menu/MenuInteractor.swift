import Foundation

/// The Interactor holds the business rules for this screen.
/// It knows nothing about UIKit, labels or table views.
@MainActor
final class MenuInteractor: NSObject, MenuInteractorInputProtocol {

    weak var output: MenuInteractorOutputProtocol?

    private let restaurant: Restaurant
    private let cart: CartStore

    init(restaurant: Restaurant, cart: CartStore) {
        self.restaurant = restaurant
        self.cart = cart
        super.init()

        // The cart can change on another tab while this screen is still open.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange),
                                               name: CartStore.didChangeNotification,
                                               object: cart)
    }

    @objc private func cartDidChange() {
        output?.didUpdateCart(currentSummary())
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

        // The cart enforces the rules: closed, sold out, the per-dish limit, and one restaurant at a time.
        switch cart.tryAdd(item, from: restaurant) {
        case .added:
            output?.didUpdateCart(currentSummary())
        case .restaurantClosed:
            output?.didFailToAdd(item, reason: .restaurantClosed)
        case .soldOut:
            output?.didFailToAdd(item, reason: .soldOut)
        case .limitReached(let limit):
            output?.didFailToAdd(item, reason: .limitReached(limit))
        case .differentRestaurant(let currentName):
            output?.didRequestReplaceCart(currentRestaurantName: currentName, itemID: id)
        }
    }

    func replaceCart(withItemID id: String) {
        guard let item = restaurant.menu.first(where: { $0.id == id }) else { return }
        cart.replaceCart(with: item, from: restaurant)
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
