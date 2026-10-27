import UIKit

/// Owns the floating "order on the way" bar above the tab bar.
///
/// It sits just above the tab bar, or above the home indicator while a pushed screen hides the tab bar.
/// While it shows, each tab's navigation controller gets a bottom safe-area inset, so the cart bars and
/// the scroll views make room for it.
@MainActor
final class OrderStatusBarHost: NSObject {

    private weak var container: UITabBarController?
    private let bar = OrderStatusBar()
    private var bottomConstraint: NSLayoutConstraint?

    /// What the bar shows now: the delivered order during its 4 s, otherwise the newest active order.
    private var deliveredOrderID: UUID?
    private var deliveredTask: Task<Void, Never>?
    private var shownOrderID: UUID?
    private var isShown = false
    private var hasConfiguredBar = false
    private var isUpdateScheduled = false

    /// Set while a push or pop is running, so the bar can move with it.
    private var transitionTop: (navigation: UINavigationController, viewController: UIViewController)?

    private static let deliveredDuration: Duration = .seconds(4)

    init(container: UITabBarController) {
        self.container = container
        super.init()
    }

    // MARK: - Set up

    func install() {
        guard let container, bar.superview == nil else { return }
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.isHidden = true
        bar.alpha = 0
        bar.onTap = { [weak self] in self?.openTracking() }
        container.view.addSubview(bar)
        let bottom = bar.bottomAnchor.constraint(equalTo: container.view.bottomAnchor)
        bottomConstraint = bottom
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.view.leadingAnchor, constant: DS.Spacing.l),
            bar.trailingAnchor.constraint(equalTo: container.view.trailingAnchor, constant: -DS.Spacing.l),
            bottom
        ])

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(trackerDidChange), name: DeliveryTracker.didChangeNotification, object: nil)
        center.addObserver(self, selector: #selector(orderDidArrive(_:)), name: DeliveryTracker.didDeliverNotification, object: nil)
        update(animated: false)
    }

    // MARK: - Updates

    /// Called from the tab bar controller's layout pass and whenever the selected tab or the top screen changes.
    func update(animated: Bool) {
        guard let container, bar.superview != nil else { return }

        let content = currentContent()
        let shouldShow = content != nil && !isTrackingScreenShowing(orderID: content?.orderID)
        shownOrderID = content?.orderID

        if let content {
            bar.configure(content.model, animated: animated && hasConfiguredBar)
            hasConfiguredBar = true
        }

        if shouldShow, bar.isHidden {
            bar.isHidden = false
        }
        let offset = bottomOffset()
        let changes = {
            self.bottomConstraint?.constant = -offset
            self.bar.alpha = shouldShow ? 1 : 0
            container.view.layoutIfNeeded()
        }
        if animated, isShown != shouldShow, !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.25, animations: changes) { _ in
                if !self.isShown { self.bar.isHidden = true }
            }
        } else {
            changes()
            bar.isHidden = !shouldShow
        }
        isShown = shouldShow
        applySafeAreaInsets()
    }

    private func currentContent() -> (model: OrderStatusBarModel, orderID: UUID)? {
        let history = HistoryStore.shared
        if let id = deliveredOrderID, let order = history.order(id: id) {
            return (makeModel(order: order, title: "Delivered", progress: 1, extraCount: 0, isDelivered: true), id)
        }
        let active = DeliveryTracker.shared.active
        guard let newest = active.first, let order = history.order(id: newest.orderID) else { return nil }
        return (makeModel(order: order, title: newest.summaryText, progress: newest.progress,
                          extraCount: active.count - 1, isDelivered: false), newest.orderID)
    }

    private func makeModel(order: PastOrder, title: String, progress: Double,
                           extraCount: Int, isDelivered: Bool) -> OrderStatusBarModel {
        OrderStatusBarModel(symbolName: order.imageName,
                            tint: UIColor(hex: order.colorHex),
                            title: title,
                            subtitle: order.restaurantName,
                            progress: progress,
                            extraCount: extraCount,
                            isDelivered: isDelivered)
    }

    // MARK: - Placement

    /// The screen on top of the selected tab, or the one a push or pop is heading to.
    private var topViewController: UIViewController? {
        if let transitionTop { return transitionTop.viewController }
        return (container?.selectedViewController as? UINavigationController)?.topViewController
    }

    private func isTrackingScreenShowing(orderID: UUID?) -> Bool {
        guard let orderID, let tracking = topViewController as? OrderTrackingViewController else { return false }
        return tracking.orderID == orderID
    }

    private func tabBarIsHidden() -> Bool {
        if let transitionTop {
            let stack = transitionTop.navigation.viewControllers
            let index = stack.firstIndex(of: transitionTop.viewController) ?? stack.count - 1
            return stack.prefix(through: max(index, 0)).contains { $0.hidesBottomBarWhenPushed }
        }
        guard let navigation = container?.selectedViewController as? UINavigationController else { return false }
        return navigation.viewControllers.contains { $0.hidesBottomBarWhenPushed }
    }

    /// Distance from the bottom edge of the tab bar controller to the bar's bottom.
    private func bottomOffset() -> CGFloat {
        guard let container else { return 0 }
        let base = tabBarIsHidden() ? container.view.safeAreaInsets.bottom : container.tabBar.frame.height
        return base + DS.Spacing.s
    }

    /// Pushes the navigation controllers' content up by the bar's height, and back to 0 when it hides.
    private func applySafeAreaInsets() {
        guard let container else { return }
        var inset: CGFloat = 0
        if isShown {
            let width = max(container.view.bounds.width - DS.Spacing.l * 2, 0)
            let height = bar.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                                     withHorizontalFittingPriority: .required,
                                                     verticalFittingPriority: .fittingSizeLevel).height
            inset = (height + DS.Spacing.s).rounded(.up)
        }
        for case let navigation as UINavigationController in container.viewControllers ?? [] {
            if navigation.additionalSafeAreaInsets.bottom != inset {
                navigation.additionalSafeAreaInsets.bottom = inset
            }
        }
    }

    // MARK: - Navigation transitions

    func navigationWillShow(_ viewController: UIViewController, in navigation: UINavigationController, animated: Bool) {
        guard navigation === container?.selectedViewController else { return }
        transitionTop = (navigation, viewController)
        guard animated, let coordinator = navigation.transitionCoordinator else {
            transitionTop = nil
            update(animated: false)
            return
        }
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.update(animated: false)
        }, completion: { [weak self] _ in
            // A cancelled swipe-back lands here too, so use whatever is really on top.
            self?.transitionTop = nil
            self?.update(animated: false)
        })
    }

    func navigationDidShow(in navigation: UINavigationController) {
        guard navigation === container?.selectedViewController, navigation.transitionCoordinator == nil else { return }
        transitionTop = nil
        update(animated: false)
    }

    // MARK: - Notifications

    /// The tracker posts "changed" before "delivered", so wait a turn: the delivered state should replace the bar, not flash it away.
    @objc private func trackerDidChange() {
        guard !isUpdateScheduled else { return }
        isUpdateScheduled = true
        Task { @MainActor [weak self] in
            self?.isUpdateScheduled = false
            self?.update(animated: true)
        }
    }

    @objc private func orderDidArrive(_ notification: Notification) {
        guard let id = notification.userInfo?["orderID"] as? UUID,
              let order = HistoryStore.shared.order(id: id) else { return }
        deliveredOrderID = id
        update(animated: true)

        let toastHost = topViewController?.view ?? container?.view
        if let toastHost {
            Toast.show("Your order from \(order.restaurantName) has arrived", in: toastHost)
        }

        deliveredTask?.cancel()
        deliveredTask = Task { [weak self] in
            try? await Task.sleep(for: Self.deliveredDuration)
            guard !Task.isCancelled else { return }
            self?.deliveredOrderID = nil
            self?.update(animated: true)
        }
    }

    // MARK: - Tap

    private func openTracking() {
        guard let shownOrderID,
              let navigation = container?.selectedViewController as? UINavigationController else { return }
        navigation.pushViewController(OrderTrackingRouter.createModule(orderID: shownOrderID), animated: true)
    }
}
