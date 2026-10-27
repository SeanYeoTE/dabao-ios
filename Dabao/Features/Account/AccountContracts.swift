import Foundation

// MARK: - The Account module, VIPER style
//
// View        AccountViewController   Shows the profile header, order stats, address and the About row.
// Interactor  AccountInteractor       Reads the profile and order history, and reports when either changes.
// Presenter   AccountPresenter        Turns the profile and stats into the text the screen shows.
// Entity      UserProfile, AccountStats (see the Models and Services folders).
// Router      AccountRouter           Builds the module, opens the edit sheet and pushes About.

/// Everything the Account screen shows.
struct AccountViewModel: Equatable {
    let header: ProfileHeaderModel
    /// nil when there are no orders yet.
    let stats: [StatItem]?
}

@MainActor
protocol AccountViewProtocol: AnyObject {
    func show(_ model: AccountViewModel)
}

@MainActor
protocol AccountPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didTapEdit()
    func didSelectAbout()
}

@MainActor
protocol AccountInteractorInputProtocol: AnyObject {
    func load()
}

@MainActor
protocol AccountInteractorOutputProtocol: AnyObject {
    func didLoad(profile: UserProfile?, stats: AccountStats)
}

@MainActor
protocol AccountRouterProtocol: AnyObject {
    func showEdit()
    func showAbout()
}
