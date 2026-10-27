import UIKit

/// The four tabs at the bottom of the app.
final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let home = UINavigationController(rootViewController: RestaurantListViewController())
        home.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)

        let cart = UINavigationController(rootViewController: CartViewController())
        cart.tabBarItem = UITabBarItem(title: "Cart", image: UIImage(systemName: "bag.fill"), tag: 1)

        let orders = UINavigationController(rootViewController: OrderHistoryRouter.createModule())
        orders.tabBarItem = UITabBarItem(title: "Orders", image: UIImage(systemName: "receipt"), tag: 2)

        let about = UINavigationController(rootViewController: AboutViewController())
        about.tabBarItem = UITabBarItem(title: "About", image: UIImage(systemName: "info.circle"), tag: 3)

        viewControllers = [home, cart, orders, about]
        view.backgroundColor = DS.Color.background

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange),
                                               name: CartStore.didChangeNotification,
                                               object: nil)
        cartDidChange()
    }

    @objc private func cartDidChange() {
        let count = CartStore.shared.itemCount
        cartTabItem?.badgeValue = count > 0 ? "\(count)" : nil
        cartTabItem?.accessibilityValue = count > 0 ? "\(count) \(count == 1 ? "item" : "items")" : nil
    }

    private var cartTabItem: UITabBarItem? {
        cartNavigationController?.tabBarItem
    }

    fileprivate var cartNavigationController: UINavigationController? {
        viewControllers?
            .compactMap { $0 as? UINavigationController }
            .first { $0.viewControllers.first is CartViewController }
    }
}

extension UIViewController {

    /// Switches to the Cart tab. We look it up by type, so reordering the tabs can't break it.
    func showCartTab() {
        guard let tabBar = tabBarController as? MainTabBarController,
              let cart = tabBar.cartNavigationController else { return }
        tabBar.selectedViewController = cart
    }
}
