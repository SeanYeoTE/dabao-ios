import Foundation

/// Works out which orders are still on their way and tells the UI when that changes.
/// Status is calculated from the clock, so there's nothing to save.
@MainActor
final class DeliveryTracker {

    static let shared = DeliveryTracker()
    /// Posted when the active statuses changed, at most once per tick.
    static let didChangeNotification = Notification.Name("DeliveryTrackerDidChange")
    /// Posted once per order that arrives while the app is running. `userInfo["orderID"]` is a `UUID`.
    static let didDeliverNotification = Notification.Name("DeliveryTrackerDidDeliver")

    var minuteLength: TimeInterval { LaunchOptions.fastDelivery ? 1 : 60 }

    /// Undelivered orders, newest first.
    private(set) var active: [DeliveryStatus] = []

    private var timer: Timer?
    private var observer: NSObjectProtocol?

    func status(for orderID: UUID) -> DeliveryStatus? {
        active.first(where: { $0.orderID == orderID })
    }

    /// Starts watching the history. Safe to call more than once.
    func start() {
        guard observer == nil else { return refresh() }
        observer = NotificationCenter.default.addObserver(
            forName: HistoryStore.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        // Orders already delivered at launch are never in `active`, so they're never announced.
        active = computeActive(now: Date())
        updateTimer()
        if !active.isEmpty {
            NotificationCenter.default.post(name: DeliveryTracker.didChangeNotification, object: self)
        }
    }

    func refresh(now: Date = Date()) {
        let previous = active
        let newActive = computeActive(now: now)
        active = newActive
        updateTimer()

        if newActive != previous {
            NotificationCenter.default.post(name: DeliveryTracker.didChangeNotification, object: self)
        }

        // Only orders we watched being active can arrive; removed orders don't count.
        let stillActive = Set(newActive.map(\.orderID))
        let length = minuteLength
        for old in previous where !stillActive.contains(old.orderID) {
            guard let order = HistoryStore.shared.order(id: old.orderID),
                  DeliveryStatus.make(for: order, now: now, minuteLength: length).stage == .delivered else { continue }
            NotificationCenter.default.post(name: DeliveryTracker.didDeliverNotification, object: self,
                                            userInfo: ["orderID": old.orderID])
        }
    }

    // MARK: - Private

    private func computeActive(now: Date) -> [DeliveryStatus] {
        let length = minuteLength
        return HistoryStore.shared.orders
            .map { DeliveryStatus.make(for: $0, now: now, minuteLength: length) }
            .filter { $0.stage != .delivered }
    }

    private func updateTimer() {
        if active.isEmpty {
            timer?.invalidate()
            timer = nil
        } else if timer == nil {
            let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
            RunLoop.main.add(newTimer, forMode: .common)
            timer = newTimer
        }
    }
}
