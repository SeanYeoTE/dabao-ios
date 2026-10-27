import Foundation

// MARK: - The Orders module, VIPER style
//
// View        OrderHistoryViewController   Shows active and past orders. Passes taps to the presenter.
// Interactor  OrderHistoryInteractor       Reads orders and delivery status, rates orders and plans reorders.
// Presenter   OrderHistoryPresenter        Turns orders into rows and cards, and decides what each tap does.
// Entity      PastOrder, ReorderPlan       Plain data (see the Models and Services folders).
// Router      OrderHistoryRouter           Builds the module, opens the Receipt, Order tracking or Cart, and shows alerts.

@MainActor
protocol OrderHistoryViewProtocol: AnyObject {
    func showOrders(active: [OrderHistoryCellModel], past: [PastOrderCellModel])
}

@MainActor
protocol OrderHistoryPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didSelectOrder(id: UUID)
    func didTapReorder(id: UUID)
    func didRate(id: UUID, stars: Int)
}

@MainActor
protocol OrderHistoryInteractorInputProtocol: AnyObject {
    func loadOrders()
    func reorderPlan(for orderID: UUID) -> ReorderPlan?
    /// The restaurant the cart holds items from, or nil when the cart is empty.
    var cartRestaurantName: String? { get }
    func applyReorder(_ plan: ReorderPlan)
    func rate(id: UUID, stars: Int)
}

@MainActor
protocol OrderHistoryInteractorOutputProtocol: AnyObject {
    func didLoadOrders(_ orders: [PastOrder], statuses: [UUID: DeliveryStatus])
}

@MainActor
protocol OrderHistoryRouterProtocol: AnyObject {
    func showReceipt(orderID: UUID)
    func showTracking(orderID: UUID)
    func showCart()
    func showAlert(title: String, message: String)
    func showReplaceCartConfirmation(title: String, message: String, onReplace: @escaping () -> Void)
}
