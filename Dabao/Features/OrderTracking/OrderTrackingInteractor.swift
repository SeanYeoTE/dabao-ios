import Foundation

/// Finds the order and works out where it is. It sends the result again whenever the tracker changes.
@MainActor
final class OrderTrackingInteractor: NSObject, OrderTrackingInteractorInputProtocol {

    weak var output: OrderTrackingInteractorOutputProtocol?

    private let orderID: UUID
    private let history: HistoryStore
    private let tracker: DeliveryTracker
    private let routeProvider: DeliveryRouteProvider
    private var route: DeliveryRoute?
    private var hasRequestedRoute = false
    private var isRequestingRoute = false

    init(orderID: UUID, history: HistoryStore, tracker: DeliveryTracker,
         routeProvider: DeliveryRouteProvider = .shared) {
        self.orderID = orderID
        self.history = history
        self.tracker = tracker
        self.routeProvider = routeProvider
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackerDidChange),
                                               name: DeliveryTracker.didChangeNotification,
                                               object: tracker)
    }

    func loadOrder() {
        guard let order = history.order(id: orderID) else {
            output?.didLoadOrder(nil, status: nil, journey: nil)
            return
        }
        // Delivered orders aren't tracked any more, so work their final status out from the clock.
        let status = tracker.status(for: orderID)
            ?? DeliveryStatus.make(for: order, now: Date(), minuteLength: tracker.minuteLength)
        requestRouteOnce(for: order)
        output?.didLoadOrder(order, status: status, journey: journey(for: order, status: status))
    }

    private func journey(for order: PastOrder, status: DeliveryStatus) -> OrderJourney {
        OrderJourney(restaurant: routeProvider.restaurantCoordinate(for: order),
                     home: DeliveryLocations.home,
                     route: route,
                     rider: route.map { RiderPosition.make(route: $0, status: status) })
    }

    private func requestRouteOnce(for order: PastOrder) {
        guard !hasRequestedRoute else { return }
        hasRequestedRoute = true
        isRequestingRoute = true
        defer { isRequestingRoute = false }
        routeProvider.route(for: order) { [weak self] route in
            guard let self else { return }
            self.route = route
            // A cache hit completes inside loadOrder, which publishes right after, so don't publish twice.
            if !self.isRequestingRoute { self.loadOrder() }
        }
    }

    @objc private func trackerDidChange() {
        loadOrder()
    }
}
