import Foundation

/// Reads the placed orders and which are still on the way. It sends the list again whenever either changes.
/// It also saves ratings and turns past orders back into carts.
@MainActor
final class OrderHistoryInteractor: NSObject, OrderHistoryInteractorInputProtocol {

    weak var output: OrderHistoryInteractorOutputProtocol?

    private let history: HistoryStore
    private let tracker: DeliveryTracker
    private let cart: CartStore
    private let catalog: CatalogStore

    init(history: HistoryStore, tracker: DeliveryTracker, cart: CartStore = .shared, catalog: CatalogStore = .shared) {
        self.history = history
        self.tracker = tracker
        self.cart = cart
        self.catalog = catalog
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(historyDidChange),
                                               name: HistoryStore.didChangeNotification,
                                               object: history)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(historyDidChange),
                                               name: DeliveryTracker.didChangeNotification,
                                               object: tracker)
    }

    func loadOrders() {
        let statuses = Dictionary(tracker.active.map { ($0.orderID, $0) }, uniquingKeysWith: { _, latest in latest })
        output?.didLoadOrders(history.orders, statuses: statuses)
    }

    func reorderPlan(for orderID: UUID) -> ReorderPlan? {
        history.order(id: orderID).map { ReorderPlanner.plan(for: $0, catalog: catalog) }
    }

    var cartRestaurantName: String? {
        cart.lines.isEmpty ? nil : cart.restaurant?.name
    }

    func applyReorder(_ plan: ReorderPlan) {
        guard case let .ready(restaurant, lines) = plan else { return }
        cart.replaceCart(with: lines, from: restaurant)
    }

    func rate(id: UUID, stars: Int) {
        // HistoryStore posts a change, which redraws the footer; a refused rating just redraws the current one.
        if !history.setRating(stars, for: id) {
            loadOrders()
        }
    }

    @objc private func historyDidChange() {
        loadOrders()
    }
}
