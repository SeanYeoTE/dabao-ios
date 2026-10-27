import UIKit

/// Turns the profile and stats into the header and tiles, and sends taps on to the router.
@MainActor
final class AccountPresenter: AccountPresenterProtocol, AccountInteractorOutputProtocol {

    weak var view: AccountViewProtocol?
    private let interactor: AccountInteractorInputProtocol
    private let router: AccountRouterProtocol

    init(view: AccountViewProtocol, interactor: AccountInteractorInputProtocol, router: AccountRouterProtocol) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    // MARK: AccountPresenterProtocol (from the view)

    func viewDidLoad() {
        interactor.load()
    }

    func didTapEdit() {
        router.showEdit()
    }

    func didSelectAbout() {
        router.showAbout()
    }

    // MARK: AccountInteractorOutputProtocol (from the interactor)

    func didLoad(profile: UserProfile?, stats: AccountStats) {
        view?.show(makeViewModel(profile: profile, stats: stats))
    }

    func makeViewModel(profile: UserProfile?, stats: AccountStats) -> AccountViewModel {
        AccountViewModel(header: makeHeader(for: profile), stats: makeStats(stats))
    }

    private func makeHeader(for profile: UserProfile?) -> ProfileHeaderModel {
        guard let profile else {
            return ProfileHeaderModel(avatar: .symbol("person.fill"),
                                      tint: DS.AvatarPalette.color(named: AvatarColor.pink.rawValue),
                                      title: "Guest",
                                      subtitle: "Add your details so riders can reach you",
                                      showsAddDetailsButton: true)
        }
        let avatar: AvatarView.Content = profile.avatarEmoji.map { .emoji($0) } ?? .initials(profile.initials)
        let contact = [ProfileValidator.formattedPhone(profile.phone), profile.email].filter { !$0.isEmpty }
        return ProfileHeaderModel(avatar: avatar,
                                  tint: DS.AvatarPalette.color(named: profile.avatarColor.rawValue),
                                  title: profile.name,
                                  subtitle: contact.isEmpty ? nil : contact.joined(separator: " · "),
                                  showsAddDetailsButton: false)
    }

    private func makeStats(_ stats: AccountStats) -> [StatItem]? {
        guard stats.orderCount > 0,
              let favourite = stats.favouriteRestaurantName,
              let since = stats.firstOrderDate else { return nil }
        let count = stats.favouriteRestaurantOrderCount
        return [
            StatItem(value: PriceFormatter.string(from: stats.totalSpent), label: "Total spent", symbolName: "creditcard"),
            StatItem(value: favourite, label: "Most ordered · \(count) \(count == 1 ? "order" : "orders")",
                     symbolName: "heart"),
            StatItem(value: since.formatted(.dateTime.day().month(.abbreviated).year()), label: "Ordering since",
                     symbolName: "calendar"),
        ]
    }
}
