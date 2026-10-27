import Foundation

/// Turns an order and its delivery status into the header, the timeline, the lines and the totals.
@MainActor
final class OrderTrackingPresenter: OrderTrackingPresenterProtocol, OrderTrackingInteractorOutputProtocol {

    weak var view: OrderTrackingViewProtocol?
    private let interactor: OrderTrackingInteractorInputProtocol
    private let router: OrderTrackingRouterProtocol

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    init(view: OrderTrackingViewProtocol, interactor: OrderTrackingInteractorInputProtocol, router: OrderTrackingRouterProtocol) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        interactor.loadOrder()
    }

    func didLoadOrder(_ order: PastOrder?, status: DeliveryStatus?, journey: OrderJourney?) {
        guard let order, let status, let journey else {
            router.close()
            return
        }
        let isDelivered = status.stage == .delivered
        let arrival = Self.timeFormatter.string(from: status.estimatedArrival)
        view?.showHeader(OrderTrackingHeaderViewModel(
            restaurantName: order.restaurantName,
            symbolName: order.imageName,
            colorHex: order.colorHex,
            etaText: isDelivered ? "Arrived" : "Arriving in \(status.minutesRemaining) min",
            arrivalText: isDelivered ? "Delivered at \(arrival)" : "Estimated \(arrival)",
            isDelivered: isDelivered,
            mapModel: mapModel(for: order, journey: journey),
            riderModel: riderModel(for: order, status: status, journey: journey)))
        view?.showTimeline(OrderTrackingTimelineViewModel(stages: DeliveryStage.allCases.map(\.title),
                                                          currentIndex: status.stage.rawValue))
        view?.showLines(order.lines.map {
            ReceiptLineViewModel(id: $0.id,
                                 quantityText: "\($0.quantity) ×",
                                 name: $0.name,
                                 notes: $0.notes.isEmpty ? nil : $0.notes,
                                 priceText: PriceFormatter.string(from: $0.subtotal))
        })
        view?.showSummary(ReceiptSummaryViewModel(subtotalText: PriceFormatter.string(from: order.subtotal),
                                                  deliveryText: PriceFormatter.string(from: order.deliveryFee),
                                                  totalText: PriceFormatter.string(from: order.total)))
    }

    private func mapModel(for order: PastOrder, journey: OrderJourney) -> OrderTrackingMapViewModel {
        OrderTrackingMapViewModel(restaurant: journey.restaurant,
                                  home: journey.home,
                                  route: journey.route?.points ?? [],
                                  isApproximateRoute: journey.route?.isApproximate ?? false,
                                  symbolName: order.imageName,
                                  colorHex: order.colorHex)
    }

    private func riderModel(for order: PastOrder, status: DeliveryStatus, journey: OrderJourney) -> OrderTrackingRiderViewModel {
        let destination = "Home"
        let distanceText: String
        let summary: String
        switch status.stage {
        case .delivered:
            distanceText = "Delivered to \(destination)"
            summary = "Map. Delivered from \(order.restaurantName) to \(destination)"
        case .onTheWay:
            if let rider = journey.rider {
                distanceText = "Rider is \(DistanceFormatter.string(meters: rider.remainingMeters)) away"
                summary = "Map. \(distanceText), on the way from \(order.restaurantName) to \(destination)"
            } else {
                distanceText = "Rider is on the way"
                summary = "Map. Rider is on the way from \(order.restaurantName) to \(destination)"
            }
        case .confirmed, .preparing:
            distanceText = "Waiting at restaurant"
            summary = "Map. Waiting at \(order.restaurantName) before delivery to \(destination)"
        }
        return OrderTrackingRiderViewModel(coordinate: journey.rider?.coordinate,
                                           isWaitingAtRestaurant: status.stage < .onTheWay,
                                           distanceText: distanceText,
                                           accessibilitySummary: summary)
    }
}
