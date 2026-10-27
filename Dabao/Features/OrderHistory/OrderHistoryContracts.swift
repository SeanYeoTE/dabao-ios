import Foundation

// MARK: - The Orders module, VIPER style
//
// View        OrderHistoryViewController   Shows the list of past orders. Passes taps to the presenter.
// Interactor  OrderHistoryInteractor       Reads the orders from HistoryStore and their delivery status, and reports changes.
// Presenter   OrderHistoryPresenter        Turns orders into the text each row shows.
// Entity      PastOrder                    Plain data (see the Models folder).
// Router      OrderHistoryRouter           Builds the module, and opens the Receipt or Order tracking.

@MainActor
protocol OrderHistoryViewProtocol: AnyObject {
    func showOrders(_ orders: [OrderHistoryCellModel])
}

@MainActor
protocol OrderHistoryPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didSelectOrder(id: UUID)
}

@MainActor
protocol OrderHistoryInteractorInputProtocol: AnyObject {
    func loadOrders()
}

@MainActor
protocol OrderHistoryInteractorOutputProtocol: AnyObject {
    func didLoadOrders(_ orders: [PastOrder], statuses: [UUID: DeliveryStatus])
}

@MainActor
protocol OrderHistoryRouterProtocol: AnyObject {
    func showReceipt(orderID: UUID)
    func showTracking(orderID: UUID)
}
