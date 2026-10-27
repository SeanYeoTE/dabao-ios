import Foundation

// MARK: - The Menu module, VIPER style
//
// View        MenuViewController   Shows what it's told. Passes taps to the presenter.
// Interactor  MenuInteractor       Business rules: what's on the menu, what can go in the cart.
// Presenter   MenuPresenter        The middle-person. Turns data into text the view can show.
// Entity      Restaurant, MenuItem Plain data (see the Models folder).
// Router      MenuRouter           Builds the module, and moves to other screens.
//
// Everything here runs on the main thread (@MainActor), because it all ends in UI updates.
//
// Each layer only talks to the others through these protocols. That's what lets
// us swap in fakes when we test the presenter on Day 14.

// MARK: View (the presenter talks to the view through this)

@MainActor
protocol MenuViewProtocol: AnyObject {
    func showLoading(_ isLoading: Bool)
    func showHeader(_ header: MenuHeaderViewModel)
    func showSections(_ sections: [MenuSectionViewModel])
    func reloadRow(_ row: MenuItemViewModel)
    func showCartBar(title: String?)
    func showMessage(title: String, message: String)
}

// MARK: Presenter (the view talks to the presenter through this)

@MainActor
protocol MenuPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didTapAdd(itemID: String)
    func didTapRemove(itemID: String)
    func didTapCartBar()
    func cartDidChange()
}

// MARK: Interactor (the presenter asks the interactor to do things)

@MainActor
protocol MenuInteractorInputProtocol: AnyObject {
    func loadMenu()
    func addItem(id: String)
    func removeItem(id: String)
}

// MARK: Interactor output (the interactor reports back to the presenter)

@MainActor
protocol MenuInteractorOutputProtocol: AnyObject {
    func didLoadMenu(restaurant: Restaurant, items: [MenuItem])
    func didUpdateCart(_ summary: CartSummary)
    func didFailToAdd(_ item: MenuItem, reason: AddToCartFailure)
}

// MARK: Router (the presenter asks the router to navigate)

@MainActor
protocol MenuRouterProtocol: AnyObject {
    func showCart()
}

// MARK: - Plain data passed between layers

struct CartSummary: Equatable {
    let quantities: [String: Int]   // menu item id -> quantity
    let itemCount: Int
    let total: Decimal
}

enum AddToCartFailure: Equatable {
    case restaurantClosed
    case soldOut
    case limitReached(Int)
    case cartFromAnotherRestaurant(String)   // name of the restaurant already in the cart
}

// MARK: - View models: exactly what the view needs, already formatted

struct MenuHeaderViewModel: Equatable {
    let title: String
    let subtitle: String
    let isOpen: Bool
}

struct MenuSectionViewModel: Equatable {
    let title: String
    let rows: [MenuItemViewModel]
}

struct MenuItemViewModel: Equatable {
    let id: String
    let name: String
    let detail: String
    let priceText: String
    let quantityText: String?
    let isSoldOut: Bool
    let isSpicy: Bool
}
