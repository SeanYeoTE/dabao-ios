import UIKit

/// Turns past orders into rows, and sends taps on to the router.
@MainActor
final class OrderHistoryPresenter: OrderHistoryPresenterProtocol, OrderHistoryInteractorOutputProtocol {

    weak var view: OrderHistoryViewProtocol?
    private let interactor: OrderHistoryInteractorInputProtocol
    private let router: OrderHistoryRouterProtocol
    private var activeOrderIDs: Set<UUID> = []

    init(view: OrderHistoryViewProtocol, interactor: OrderHistoryInteractorInputProtocol, router: OrderHistoryRouterProtocol) {
        self.view = view
        self.interactor = interactor
        self.router = router
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

    // MARK: OrderHistoryInteractorOutputProtocol (from the interactor)

    func didLoadOrders(_ orders: [PastOrder], statuses: [UUID: DeliveryStatus]) {
        activeOrderIDs = Set(statuses.keys)
        view?.showOrders(orders.map { makeRow(for: $0, status: statuses[$0.id]) })
    }

    func makeRow(for order: PastOrder, status: DeliveryStatus? = nil) -> OrderHistoryCellModel {
        let dateText = OrderDateFormatter.string(from: order.placedAt)
        return OrderHistoryCellModel(
            id: order.id,
            restaurantName: order.restaurantName,
            dateText: status?.summaryText ?? dateText,
            itemsSummary: order.lines.map { "\($0.quantity) × \($0.name)" }.joined(separator: ", "),
            totalText: PriceFormatter.string(from: order.total),
            symbolName: order.imageName,
            tint: UIColor(hex: order.colorHex)
        )
    }
}
