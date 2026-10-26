import Foundation

/// Reads the placed orders. It sends the list again whenever HistoryStore changes.
@MainActor
final class OrderHistoryInteractor: NSObject, OrderHistoryInteractorInputProtocol {

    weak var output: OrderHistoryInteractorOutputProtocol?

    private let history: HistoryStore

    init(history: HistoryStore) {
        self.history = history
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(historyDidChange),
                                               name: HistoryStore.didChangeNotification,
                                               object: history)
    }

    func loadOrders() {
        output?.didLoadOrders(history.orders)
    }

    @objc private func historyDidChange() {
        loadOrders()
    }
}
