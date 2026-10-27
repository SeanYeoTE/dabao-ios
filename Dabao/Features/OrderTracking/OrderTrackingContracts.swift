import Foundation

// MARK: - The Order tracking module, VIPER style (read-only)
//
// View        OrderTrackingViewController   Shows the map, the ETA, the stage timeline, the items and the total.
// Interactor  OrderTrackingInteractor       Finds the order, its delivery status, its route and the rider, and reports each change.
// Presenter   OrderTrackingPresenter        Turns the status, route and rider into text and plain map values.
// Entity      PastOrder, DeliveryStatus,    The saved order, where it is on the way, and the route it takes (see Models).
//             DeliveryRoute, RiderPosition
// Router      OrderTrackingRouter           Builds the module, and goes back if the order has vanished.

@MainActor
protocol OrderTrackingViewProtocol: AnyObject {
    func showHeader(_ header: OrderTrackingHeaderViewModel)
    func showTimeline(_ timeline: OrderTrackingTimelineViewModel)
    func showLines(_ lines: [ReceiptLineViewModel])
    func showSummary(_ summary: ReceiptSummaryViewModel)
}

@MainActor
protocol OrderTrackingPresenterProtocol: AnyObject {
    func viewDidLoad()
}

@MainActor
protocol OrderTrackingInteractorInputProtocol: AnyObject {
    func loadOrder()
}

@MainActor
protocol OrderTrackingInteractorOutputProtocol: AnyObject {
    func didLoadOrder(_ order: PastOrder?, status: DeliveryStatus?, journey: OrderJourney?)
}

@MainActor
protocol OrderTrackingRouterProtocol: AnyObject {
    func close()
}

// MARK: - Journey (interactor -> presenter)

/// Where the order is going. `route` and `rider` stay nil until the route arrives.
struct OrderJourney: Equatable {
    let restaurant: GeoPoint
    let home: GeoPoint
    let route: DeliveryRoute?
    let rider: RiderPosition?
}

// MARK: - View models

struct OrderTrackingHeaderViewModel: Equatable {
    let restaurantName: String
    let symbolName: String
    let colorHex: String
    let etaText: String         // "Arriving in 12 min" or "Arrived"
    let arrivalText: String     // "Estimated 6:42 PM"
    let isDelivered: Bool
    let mapModel: OrderTrackingMapViewModel
    let riderModel: OrderTrackingRiderViewModel
}

/// What stays the same while the rider moves. It changes once, when the route arrives.
struct OrderTrackingMapViewModel: Equatable {
    let restaurant: GeoPoint
    let home: GeoPoint
    let route: [GeoPoint]       // empty while the route is loading
    let isApproximateRoute: Bool
    let symbolName: String
    let colorHex: String
}

struct OrderTrackingRiderViewModel: Equatable {
    let coordinate: GeoPoint?
    let isWaitingAtRestaurant: Bool
    let distanceText: String            // "Rider is 1.2 km away", "Waiting at restaurant" or "Delivered to Home"
    let accessibilitySummary: String
}

struct OrderTrackingTimelineViewModel: Equatable {
    let stages: [String]
    let currentIndex: Int
}
