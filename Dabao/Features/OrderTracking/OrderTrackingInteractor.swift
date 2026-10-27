import Foundation

/// Finds the order and works out where it is. It sends the result again whenever the tracker changes.
@MainActor
final class OrderTrackingInteractor: NSObject, OrderTrackingInteractorInputProtocol {

    weak var output: OrderTrackingInteractorOutputProtocol?

    private let orderID: UUID
    private let history: HistoryStore
    private let tracker: DeliveryTracker

    init(orderID: UUID, history: HistoryStore, tracker: DeliveryTracker) {
        self.orderID = orderID
        self.history = history
        self.tracker = tracker
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackerDidChange),
                                               name: DeliveryTracker.didChangeNotification,
                                               object: tracker)
    }

    func loadOrder() {
        guard let order = history.order(id: orderID) else {
            output?.didLoadOrder(nil, status: nil)
            return
        }
        // Delivered orders aren't tracked any more, so work their final status out from the clock.
        let status = tracker.status(for: orderID)
            ?? DeliveryStatus.make(for: order, now: Date(), minuteLength: tracker.minuteLength)
        output?.didLoadOrder(order, status: status)
    }

    @objc private func trackerDidChange() {
        loadOrder()
    }
}
