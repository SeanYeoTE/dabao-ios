import Foundation

/// The Presenter sits in the middle. It reacts to taps from the view,
/// asks the interactor to do the work, and turns the results into
/// view models (ready-to-show strings) for the view.
@MainActor
final class MenuPresenter: MenuPresenterProtocol, MenuInteractorOutputProtocol {

    weak var view: MenuViewProtocol?
    private let interactor: MenuInteractorInputProtocol
    private let router: MenuRouterProtocol

    private var items: [MenuItem] = []
    private var quantities: [String: Int] = [:]

    init(view: MenuViewProtocol, interactor: MenuInteractorInputProtocol, router: MenuRouterProtocol) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    // MARK: MenuPresenterProtocol (from the view)

    func viewDidLoad() {
        view?.showLoading(true)
        interactor.loadMenu()
    }

    func didTapAdd(itemID: String) {
        interactor.addItem(id: itemID)
    }

    func didTapRemove(itemID: String) {
        interactor.removeItem(id: itemID)
    }

    func didTapCartBar() {
        router.showCart()
    }

    // MARK: MenuInteractorOutputProtocol (from the interactor)

    func didLoadMenu(restaurant: Restaurant, items: [MenuItem]) {
        self.items = items
        view?.showLoading(false)
        view?.showHeader(makeHeader(for: restaurant))
        view?.showSections(makeSections())
    }

    func didUpdateCart(_ summary: CartSummary) {
        let changedIDs = Set(summary.quantities.keys).union(quantities.keys)
            .filter { summary.quantities[$0] != quantities[$0] }
        quantities = summary.quantities

        for item in items where changedIDs.contains(item.id) {
            view?.reloadRow(makeRow(for: item))
        }

        if summary.itemCount == 0 {
            view?.showCartBar(title: nil)
        } else {
            let noun = summary.itemCount == 1 ? "item" : "items"
            view?.showCartBar(title: "View cart · \(summary.itemCount) \(noun) · \(PriceFormatter.string(from: summary.total))")
        }
    }

    func didFailToAdd(_ item: MenuItem, reason: AddToCartFailure) {
        switch reason {
        case .restaurantClosed:
            view?.showMessage(title: "Closed now", message: "This restaurant isn't taking orders right now. Please try again later!")
        case .soldOut:
            view?.showMessage(title: "Sold out", message: "Sorry, \(item.name) is sold out today.")
        case .limitReached(let limit):
            view?.showMessage(title: "That's a lot of \(item.name)!", message: "You can order up to \(limit) of each dish.")
        case .cartFromAnotherRestaurant(let currentName):
            view?.showMessage(title: "Cart from another restaurant", message: "Your cart has items from \(currentName). Finish that order or clear your cart before adding dishes from here.")
        }
    }

    // MARK: Building view models

    private func makeHeader(for restaurant: Restaurant) -> MenuHeaderViewModel {
        let rating = String(format: "%.1f", restaurant.rating)
        return MenuHeaderViewModel(
            title: restaurant.name,
            subtitle: "\(restaurant.cuisine) · ★ \(rating) · \(restaurant.deliveryMinutes) min",
            isOpen: restaurant.isOpen
        )
    }

    private func makeSections() -> [MenuSectionViewModel] {
        var sections: [MenuSectionViewModel] = []
        for item in items {
            let row = makeRow(for: item)
            if let last = sections.last, last.title == item.category {
                sections[sections.count - 1] = MenuSectionViewModel(title: last.title, rows: last.rows + [row])
            } else {
                sections.append(MenuSectionViewModel(title: item.category, rows: [row]))
            }
        }
        return sections
    }

    func makeRow(for item: MenuItem) -> MenuItemViewModel {
        let quantity = quantities[item.id] ?? 0
        return MenuItemViewModel(
            id: item.id,
            name: item.name,
            detail: item.description,
            priceText: PriceFormatter.string(from: item.price),
            quantityText: quantity > 0 ? "×\(quantity)" : nil,
            isSoldOut: item.isSoldOut,
            isSpicy: item.isSpicy
        )
    }
}
