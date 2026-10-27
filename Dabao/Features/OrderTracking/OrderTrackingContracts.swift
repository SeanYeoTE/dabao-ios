import Foundation

// MARK: - The Order tracking module, VIPER style (read-only)
//
// View        OrderTrackingViewController   Shows the ETA, the stage timeline, the items and the total.
// Interactor  OrderTrackingInteractor       Finds the order and its delivery status, and reports each change.
// Presenter   OrderTrackingPresenter        Turns the status into text for the header and the timeline.
// Entity      PastOrder, DeliveryStatus     The saved order, and where it is on the way (see Models).
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
    func didLoadOrder(_ order: PastOrder?, status: DeliveryStatus?)
}

@MainActor
protocol OrderTrackingRouterProtocol: AnyObject {
    func close()
}

// MARK: - View models

struct OrderTrackingHeaderViewModel: Equatable {
    let restaurantName: String
    let symbolName: String
    let colorHex: String
    let etaText: String         // "Arriving in 12 min" or "Arrived"
    let arrivalText: String     // "Estimated 6:42 PM"
    let isDelivered: Bool
}

struct OrderTrackingTimelineViewModel: Equatable {
    let stages: [String]
    let currentIndex: Int
}
