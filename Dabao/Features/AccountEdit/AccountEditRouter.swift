import UIKit

/// Builds the edit sheet inside its own navigation controller (for Cancel and Save), and dismisses it.
@MainActor
final class AccountEditRouter: AccountEditRouterProtocol {

    weak var viewController: UIViewController?

    static func createModule(profiles: ProfileStore = .shared) -> UIViewController {
        let view = AccountEditViewController()
        let interactor = AccountEditInteractor(profiles: profiles)
        let router = AccountEditRouter()
        let presenter = AccountEditPresenter(view: view, interactor: interactor, router: router)

        view.presenter = presenter      // view -> presenter (strong)
        router.viewController = view    // router -> view (weak)

        let navigation = UINavigationController(rootViewController: view)
        navigation.modalPresentationStyle = .pageSheet
        navigation.sheetPresentationController?.detents = [.large()]
        return navigation
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }
}
