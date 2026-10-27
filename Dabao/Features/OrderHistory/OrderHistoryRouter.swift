import UIKit

/// Builds the Orders module and opens the Receipt, or Order tracking, for an order.
@MainActor
final class OrderHistoryRouter: OrderHistoryRouterProtocol {

    weak var viewController: UIViewController?

    static func createModule(history: HistoryStore = .shared, tracker: DeliveryTracker = .shared) -> UIViewController {
        let view = OrderHistoryViewController()
        let interactor = OrderHistoryInteractor(history: history, tracker: tracker)
        let router = OrderHistoryRouter()
        let presenter = OrderHistoryPresenter(view: view, interactor: interactor, router: router)

        view.presenter = presenter      // view -> presenter (strong)
        interactor.output = presenter   // interactor -> presenter (weak)
        router.viewController = view    // router -> view (weak)

        return view
    }

    func showReceipt(orderID: UUID) {
        let receipt = ReceiptRouter.createModule(orderID: orderID)
        viewController?.navigationController?.pushViewController(receipt, animated: true)
    }

    func showTracking(orderID: UUID) {
        let tracking = OrderTrackingRouter.createModule(orderID: orderID)
        viewController?.navigationController?.pushViewController(tracking, animated: true)
    }
}
