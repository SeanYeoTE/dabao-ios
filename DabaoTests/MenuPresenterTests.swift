import XCTest
@testable import Dabao

/// A first example of testing a VIPER presenter.
/// Because the presenter only knows its view, interactor and router through protocols,
/// we can hand it fakes and check what it does, with no UIKit screens involved.
@MainActor
final class MenuPresenterTests: XCTestCase {

    // MARK: Fakes

    final class FakeView: MenuViewProtocol {
        var shownSections: [MenuSectionViewModel] = []
        var reloadedRows: [MenuItemViewModel] = []
        var cartBar: CartBarViewModel??
        var messages: [String] = []
        var replacePrompts: [String] = []
        var confirmReplace: (() -> Void)?

        func showLoading(_ isLoading: Bool) {}
        func showHeader(_ header: MenuHeaderViewModel) {}
        func showSections(_ sections: [MenuSectionViewModel]) { shownSections = sections }
        func reloadRow(_ row: MenuItemViewModel) { reloadedRows.append(row) }
        func showCartBar(_ bar: CartBarViewModel?) { cartBar = .some(bar) }
        func showMessage(title: String, message: String) { messages.append(title) }
        func showReplaceCartConfirmation(currentRestaurantName: String, onReplace: @escaping () -> Void) {
            replacePrompts.append(currentRestaurantName)
            confirmReplace = onReplace
        }
    }

    final class FakeInteractor: MenuInteractorInputProtocol {
        var addedIDs: [String] = []
        var replacedIDs: [String] = []
        func loadMenu() {}
        func addItem(id: String) { addedIDs.append(id) }
        func removeItem(id: String) {}
        func replaceCart(withItemID id: String) { replacedIDs.append(id) }
    }

    final class FakeRouter: MenuRouterProtocol {
        var didShowCart = false
        func showCart() { didShowCart = true }
    }

    // MARK: Test data

    private let rice = MenuItem(id: "a", name: "Chicken Rice", description: "", price: 4.5,
                                category: "Mains", isSoldOut: false, isSpicy: false)
    private let tea = MenuItem(id: "b", name: "Teh Peng", description: "", price: 2,
                               category: "Drinks", isSoldOut: false, isSpicy: false)

    private func makeRestaurant() -> Restaurant {
        Restaurant(id: "r", name: "Test Kitchen", cuisine: "Hawker", rating: 4.5,
                   deliveryMinutes: 20, deliveryFee: 2, isOpen: true,
                   imageName: "fork.knife", menu: [rice, tea])
    }

    // MARK: Tests

    func test_tappingAdd_asksInteractorToAddThatItem() {
        let view = FakeView()
        let interactor = FakeInteractor()
        let presenter = MenuPresenter(view: view, interactor: interactor, router: FakeRouter())

        presenter.didTapAdd(itemID: "a")

        XCTAssertEqual(interactor.addedIDs, ["a"])
    }

    func test_tappingCartBar_asksRouterToShowCart() {
        let router = FakeRouter()
        let presenter = MenuPresenter(view: FakeView(), interactor: FakeInteractor(), router: router)

        presenter.didTapCartBar()

        XCTAssertTrue(router.didShowCart)
    }

    func test_loadedMenu_isGroupedIntoSectionsByCategory() {
        let view = FakeView()
        let presenter = MenuPresenter(view: view, interactor: FakeInteractor(), router: FakeRouter())

        presenter.didLoadMenu(restaurant: makeRestaurant(), items: [rice, tea])

        XCTAssertEqual(view.shownSections.map(\.title), ["Mains", "Drinks"])
        XCTAssertEqual(view.shownSections.first?.rows.first?.priceText, "$4.50")
    }

    func test_cartUpdate_showsCartBarWithCountAndTotal() {
        let view = FakeView()
        let presenter = MenuPresenter(view: view, interactor: FakeInteractor(), router: FakeRouter())
        presenter.didLoadMenu(restaurant: makeRestaurant(), items: [rice, tea])

        presenter.didUpdateCart(CartSummary(quantities: ["a": 2], itemCount: 2, total: 9))

        XCTAssertEqual(view.cartBar, .some(CartBarViewModel(itemCount: 2, totalText: "$9.00")))
        XCTAssertEqual(view.reloadedRows.last?.quantityText, "×2")
    }

    func test_differentRestaurant_asksViewToConfirm_thenReplacesCart() {
        let view = FakeView()
        let interactor = FakeInteractor()
        let presenter = MenuPresenter(view: view, interactor: interactor, router: FakeRouter())

        presenter.didRequestReplaceCart(currentRestaurantName: "Other Place", itemID: "a")
        XCTAssertEqual(view.replacePrompts, ["Other Place"])
        XCTAssertTrue(interactor.replacedIDs.isEmpty)

        view.confirmReplace?()
        XCTAssertEqual(interactor.replacedIDs, ["a"])
    }

    // TODO (Day 14): write a test that checks the "sold out" message appears
    // when the interactor reports `.soldOut`.
}
