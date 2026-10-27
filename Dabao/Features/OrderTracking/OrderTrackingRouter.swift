import UIKit

/// Builds the Order tracking module.
@MainActor
final class OrderTrackingRouter: OrderTrackingRouterProtocol {

    weak var viewController: UIViewController?

    static func createModule(orderID: UUID,
                             history: HistoryStore = .shared,
                             tracker: DeliveryTracker = .shared) -> UIViewController {
        let view = OrderTrackingViewController(orderID: orderID)
        let interactor = OrderTrackingInteractor(orderID: orderID, history: history, tracker: tracker)
        let router = OrderTrackingRouter()
        let presenter = OrderTrackingPresenter(view: view, interactor: interactor, router: router)

        view.presenter = presenter      // view -> presenter (strong)
        interactor.output = presenter   // interactor -> presenter (weak)
        router.viewController = view    // router -> view (weak)

        return view
    }

    func close() {
        viewController?.navigationController?.popViewController(animated: true)
    }
}
