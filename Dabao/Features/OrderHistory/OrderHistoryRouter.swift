import UIKit

/// Builds the Orders module, opens the Receipt, Order tracking or Cart, and shows the reorder alerts.
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

    func showCart() {
        viewController?.showCartTab()
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController?.present(alert, animated: true)
    }

    func showReplaceCartConfirmation(title: String, message: String, onReplace: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Replace", style: .destructive) { _ in onReplace() })
        viewController?.present(alert, animated: true)
    }
}
