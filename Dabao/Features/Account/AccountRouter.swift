import UIKit

/// Builds the Account module, presents the edit sheet and pushes About.
@MainActor
final class AccountRouter: AccountRouterProtocol {

    weak var viewController: UIViewController?
    private let profiles: ProfileStore

    init(profiles: ProfileStore) {
        self.profiles = profiles
    }

    static func createModule(profiles: ProfileStore = .shared, history: HistoryStore = .shared) -> UIViewController {
        let view = AccountViewController()
        let interactor = AccountInteractor(profiles: profiles, history: history)
        let router = AccountRouter(profiles: profiles)
        let presenter = AccountPresenter(view: view, interactor: interactor, router: router)

        view.presenter = presenter      // view -> presenter (strong)
        interactor.output = presenter   // interactor -> presenter (weak)
        router.viewController = view    // router -> view (weak)

        return view
    }

    func showEdit() {
        viewController?.present(AccountEditRouter.createModule(profiles: profiles), animated: true)
    }

    func showAbout() {
        let about = AboutViewController()
        about.navigationItem.largeTitleDisplayMode = .never
        viewController?.navigationController?.pushViewController(about, animated: true)
    }
}
