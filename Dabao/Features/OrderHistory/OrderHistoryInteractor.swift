import Foundation

/// Reads the placed orders and which are still on the way. It sends the list again whenever either changes.
@MainActor
final class OrderHistoryInteractor: NSObject, OrderHistoryInteractorInputProtocol {

    weak var output: OrderHistoryInteractorOutputProtocol?

    private let history: HistoryStore
    private let tracker: DeliveryTracker

    init(history: HistoryStore, tracker: DeliveryTracker) {
        self.history = history
        self.tracker = tracker
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(historyDidChange),
                                               name: HistoryStore.didChangeNotification,
                                               object: history)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(historyDidChange),
                                               name: DeliveryTracker.didChangeNotification,
                                               object: tracker)
    }

    func loadOrders() {
        let statuses = Dictionary(tracker.active.map { ($0.orderID, $0) }, uniquingKeysWith: { _, latest in latest })
        output?.didLoadOrders(history.orders, statuses: statuses)
    }

    @objc private func historyDidChange() {
        loadOrders()
    }
}
