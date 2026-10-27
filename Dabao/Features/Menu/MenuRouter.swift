import UIKit

/// The Router builds the module (wires up V, I, P) and handles navigation away from it.
@MainActor
final class MenuRouter: MenuRouterProtocol {

    weak var viewController: UIViewController?

    /// Builds a ready-to-show Menu screen. This is the only way other screens
    /// create a Menu, so they never need to know about the presenter or interactor.
    static func createModule(restaurant: Restaurant, cart: CartStore) -> UIViewController {
        let view = MenuViewController()
        // A restaurant page is a drill-down: hide the tab bar and rely on the Back button.
        view.hidesBottomBarWhenPushed = true
        let interactor = MenuInteractor(restaurant: restaurant, cart: cart)
        let router = MenuRouter()
        let presenter = MenuPresenter(view: view, interactor: interactor, router: router)

        view.presenter = presenter      // view -> presenter (strong)
        interactor.output = presenter   // interactor -> presenter (weak)
        router.viewController = view    // router -> view (weak)

        return view
    }

    func showCart() {
        // The cart is a tab, so we switch tabs rather than pushing a new screen.
        viewController?.showCartTab()
    }
}
