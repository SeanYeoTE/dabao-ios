import Foundation

// MARK: - The Receipt module, VIPER style (read-only)
//
// View        ReceiptViewController   Shows one placed order. Nothing on it can be changed.
// Interactor  ReceiptInteractor       Finds the order in HistoryStore.
// Presenter   ReceiptPresenter        Turns the order into text for the header, the lines and the totals.
// Entity      PastOrder               A snapshot taken when the order was placed (see the Models folder).
// Router      ReceiptRouter           Builds the module, and goes back if the order has vanished.

@MainActor
protocol ReceiptViewProtocol: AnyObject {
    func showHeader(_ header: ReceiptHeaderViewModel)
    func showLines(_ lines: [ReceiptLineViewModel])
    func showSummary(_ summary: ReceiptSummaryViewModel)
}

@MainActor
protocol ReceiptPresenterProtocol: AnyObject {
    func viewDidLoad()
}

@MainActor
protocol ReceiptInteractorInputProtocol: AnyObject {
    func loadOrder()
}

@MainActor
protocol ReceiptInteractorOutputProtocol: AnyObject {
    func didLoadOrder(_ order: PastOrder?)
}

@MainActor
protocol ReceiptRouterProtocol: AnyObject {
    func close()
}

// MARK: - View models

struct ReceiptHeaderViewModel: Equatable {
    let restaurantName: String
    let dateText: String
    let symbolName: String
    let colorHex: String
}

struct ReceiptLineViewModel: Equatable, Identifiable {
    let id: UUID
    let quantityText: String    // "2 ×"
    let name: String
    let notes: String?
    let priceText: String
}

struct ReceiptSummaryViewModel: Equatable {
    let subtotalText: String
    let deliveryText: String
    let totalText: String
}
