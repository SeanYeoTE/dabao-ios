import UIKit

/// Turns past orders into rows, and sends taps on to the router.
@MainActor
final class OrderHistoryPresenter: OrderHistoryPresenterProtocol, OrderHistoryInteractorOutputProtocol {

    weak var view: OrderHistoryViewProtocol?
    private let interactor: OrderHistoryInteractorInputProtocol
    private let router: OrderHistoryRouterProtocol

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
        router.showReceipt(orderID: id)
    }

    // MARK: OrderHistoryInteractorOutputProtocol (from the interactor)

    func didLoadOrders(_ orders: [PastOrder]) {
        view?.showOrders(orders.map(makeRow(for:)))
    }

    func makeRow(for order: PastOrder) -> OrderHistoryCellModel {
        OrderHistoryCellModel(
            id: order.id,
            restaurantName: order.restaurantName,
            dateText: OrderDateFormatter.string(from: order.placedAt),
            itemsSummary: order.lines.map { "\($0.quantity) × \($0.name)" }.joined(separator: ", "),
            totalText: PriceFormatter.string(from: order.total),
            symbolName: order.imageName,
            tint: UIColor(hex: order.colorHex)
        )
    }
}
