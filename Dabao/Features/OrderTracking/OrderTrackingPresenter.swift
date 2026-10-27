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

    func didLoadOrder(_ order: PastOrder?, status: DeliveryStatus?) {
        guard let order, let status else {
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
            isDelivered: isDelivered))
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
}
