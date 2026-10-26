import UIKit

/// Builds the Receipt module.
@MainActor
final class ReceiptRouter: ReceiptRouterProtocol {

    weak var viewController: UIViewController?

    static func createModule(orderID: UUID, history: HistoryStore = .shared) -> UIViewController {
        let view = ReceiptViewController()
        let interactor = ReceiptInteractor(orderID: orderID, history: history)
        let router = ReceiptRouter()
        let presenter = ReceiptPresenter(view: view, interactor: interactor, router: router)

        view.presenter = presenter      // view -> presenter (strong)
        interactor.output = presenter   // interactor -> presenter (weak)
        router.viewController = view    // router -> view (weak)

        return view
    }

    func close() {
        viewController?.navigationController?.popViewController(animated: true)
    }
}
