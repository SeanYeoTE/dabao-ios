import UIKit

/// Turns orders into active rows and past order cards, and decides what each tap does.
@MainActor
final class OrderHistoryPresenter: OrderHistoryPresenterProtocol, OrderHistoryInteractorOutputProtocol {

    weak var view: OrderHistoryViewProtocol?
    private let interactor: OrderHistoryInteractorInputProtocol
    private let router: OrderHistoryRouterProtocol
    private let minuteLength: () -> TimeInterval
    private let now: () -> Date
    private var activeOrderIDs: Set<UUID> = []

    init(view: OrderHistoryViewProtocol, interactor: OrderHistoryInteractorInputProtocol, router: OrderHistoryRouterProtocol,
         minuteLength: @escaping () -> TimeInterval = { DeliveryTracker.shared.minuteLength },
         now: @escaping () -> Date = { Date() }) {
        self.view = view
        self.interactor = interactor
        self.router = router
        self.minuteLength = minuteLength
        self.now = now
    }

    // MARK: OrderHistoryPresenterProtocol (from the view)

    func viewDidLoad() {
        interactor.loadOrders()
    }

    func didSelectOrder(id: UUID) {
        if activeOrderIDs.contains(id) {
            router.showTracking(orderID: id)
        } else {
            router.showReceipt(orderID: id)
        }
    }

    func didTapReorder(id: UUID) {
        guard let plan = interactor.reorderPlan(for: id) else { return }
        switch plan {
        case .restaurantMissing(let name):
            router.showAlert(title: "Restaurant unavailable", message: "\(name) is no longer on Dabao.")
        case .restaurantClosed(let name):
            router.showAlert(title: "\(name) is closed", message: "You can reorder when it opens again.")
        case .itemsUnavailable(let names):
            router.showAlert(title: "Some items are unavailable",
                             message: "Sold out or no longer on the menu: \(names.joined(separator: ", ")).")
        case .ready(let restaurant, _):
            guard let current = interactor.cartRestaurantName else {
                return reorder(plan)
            }
            router.showReplaceCartConfirmation(
                title: "Replace your cart?",
                message: "Your cart has items from \(current). Start a new cart from \(restaurant.name)?"
            ) { [weak self] in
                self?.reorder(plan)
            }
        }
    }

    func didRate(id: UUID, stars: Int) {
        interactor.rate(id: id, stars: stars)
    }

    // MARK: OrderHistoryInteractorOutputProtocol (from the interactor)

    func didLoadOrders(_ orders: [PastOrder], statuses: [UUID: DeliveryStatus]) {
        activeOrderIDs = Set(statuses.keys)
        let active = orders.filter { statuses[$0.id] != nil }.map { makeRow(for: $0, status: statuses[$0.id]) }
        let date = now()
        let past = orders.filter { statuses[$0.id] == nil }.map { makeCard(for: $0, now: date) }
        view?.showOrders(active: active, past: past)
    }

    func makeRow(for order: PastOrder, status: DeliveryStatus? = nil) -> OrderHistoryCellModel {
        let dateText = OrderDateFormatter.string(from: order.placedAt)
        return OrderHistoryCellModel(
            id: order.id,
            restaurantName: order.restaurantName,
            dateText: status?.summaryText ?? dateText,
            itemsSummary: itemsSummary(for: order),
            totalText: PriceFormatter.string(from: order.total),
            symbolName: order.imageName,
            tint: UIColor(hex: order.colorHex)
        )
    }

    func makeCard(for order: PastOrder, now: Date) -> PastOrderCellModel {
        let length = minuteLength()
        let delivered = order.deliveredAt(minuteLength: length)
        return PastOrderCellModel(
            id: order.id,
            restaurantName: order.restaurantName,
            totalText: PriceFormatter.string(from: order.total),
            dateText: "Delivered on \(OrderDateFormatter.deliveredString(from: delivered))",
            itemsSummary: itemsSummary(for: order),
            symbolName: order.imageName,
            tint: UIColor(hex: order.colorHex),
            footer: footer(for: order, now: now, minuteLength: length)
        )
    }

    // MARK: - Private

    private func reorder(_ plan: ReorderPlan) {
        interactor.applyReorder(plan)
        router.showCart()
    }

    private func itemsSummary(for order: PastOrder) -> String {
        order.lines.map { "\($0.quantity) × \($0.name)" }.joined(separator: ", ")
    }

    private func footer(for order: PastOrder, now: Date, minuteLength: TimeInterval) -> RatingFooterModel? {
        let deadline = OrderDateFormatter.deadlineString(from: RatingPolicy.deadline(for: order, minuteLength: minuteLength))
        let canRate = RatingPolicy.canRate(order, now: now, minuteLength: minuteLength)
        switch (order.rating, canRate) {
        case (nil, true):
            return RatingFooterModel(title: "Tap to rate", subtitle: "by \(deadline)", rating: nil, isEditable: true)
        case (let rating?, true):
            return RatingFooterModel(title: "You rated", subtitle: "Change by \(deadline)", rating: rating, isEditable: true)
        case (let rating?, false):
            return RatingFooterModel(title: "You rated", subtitle: nil, rating: rating, isEditable: false)
        case (nil, false):
            return nil
        }
    }
}
