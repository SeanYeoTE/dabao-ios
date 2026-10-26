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
        // TEMP-DEBUG
        if let tab = UserDefaults.standard.string(forKey: "dbgTab"), let i = Int(tab) { selectedIndex = i }
        if let push = UserDefaults.standard.string(forKey: "dbgPush") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                if push.hasPrefix("r"), let r = CatalogStore.shared.restaurant(id: push) {
                    (viewControllers?[0] as? UINavigationController)?.pushViewController(MenuRouter.createModule(restaurant: r, cart: .shared), animated: false)
                }
                if push == "note", let l = CartStore.shared.lines.first { CartStore.shared.setNotes(lineID: l.id, to: "Please no chilli, extra cucumber, rice on the side and cut the chicken into small pieces for my toddler thanks") }
                if push == "toast", let nav = viewControllers?[1] as? UINavigationController { Toast.show("Order placed", in: nav.viewControllers[0].view) }
                if push == "receipt", let o = HistoryStore.shared.orders.first {
                    (viewControllers?[2] as? UINavigationController)?.pushViewController(ReceiptRouter.createModule(orderID: o.id), animated: false)
                }
            }
        }
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
