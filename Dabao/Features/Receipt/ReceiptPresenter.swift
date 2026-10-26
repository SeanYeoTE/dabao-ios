import Foundation

/// Turns a placed order into the header, the lines and the totals.
@MainActor
final class ReceiptPresenter: ReceiptPresenterProtocol, ReceiptInteractorOutputProtocol {

    weak var view: ReceiptViewProtocol?
    private let interactor: ReceiptInteractorInputProtocol
    private let router: ReceiptRouterProtocol

    init(view: ReceiptViewProtocol, interactor: ReceiptInteractorInputProtocol, router: ReceiptRouterProtocol) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        interactor.loadOrder()
    }

    func didLoadOrder(_ order: PastOrder?) {
        // Orders are never deleted today; if one is missing, there's nothing to show.
        guard let order else {
            router.close()
            return
        }
        view?.showHeader(ReceiptHeaderViewModel(restaurantName: order.restaurantName,
                                                dateText: OrderDateFormatter.string(from: order.placedAt),
                                                symbolName: order.imageName,
                                                colorHex: order.colorHex))
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
