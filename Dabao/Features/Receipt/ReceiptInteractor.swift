import Foundation

/// Finds the order to show. Receipts come from the saved snapshot, never from the catalogue.
@MainActor
final class ReceiptInteractor: ReceiptInteractorInputProtocol {

    weak var output: ReceiptInteractorOutputProtocol?

    private let orderID: UUID
    private let history: HistoryStore

    init(orderID: UUID, history: HistoryStore) {
        self.orderID = orderID
        self.history = history
    }

    func loadOrder() {
        output?.didLoadOrder(history.order(id: orderID))
    }
}
