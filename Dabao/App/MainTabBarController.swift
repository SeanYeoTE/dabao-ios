import UIKit

/// The three tabs at the bottom of the app.
final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let restaurants = UINavigationController(rootViewController: RestaurantListViewController())
        restaurants.tabBarItem = UITabBarItem(title: "Restaurants",
                                              image: UIImage(systemName: "fork.knife"),
                                              tag: 0)

        let cart = UINavigationController(rootViewController: CartViewController())
        cart.tabBarItem = UITabBarItem(title: "Cart",
                                       image: UIImage(systemName: "bag"),
                                       tag: 1)

        let about = UINavigationController(rootViewController: AboutViewController())
        about.tabBarItem = UITabBarItem(title: "About",
                                        image: UIImage(systemName: "info.circle"),
                                        tag: 2)

        viewControllers = [restaurants, cart, about]

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange),
                                               name: CartStore.didChangeNotification,
                                               object: nil)
    }

    @objc private func cartDidChange() {
        let count = CartStore.shared.itemCount
        viewControllers?[1].tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }
}
