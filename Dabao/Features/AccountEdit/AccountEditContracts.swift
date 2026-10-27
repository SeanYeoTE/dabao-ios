import UIKit

// MARK: - The edit-profile sheet, VIPER style
//
// View        AccountEditViewController   The form: avatar preview, emoji and colour pickers, name, phone and email.
// Interactor  AccountEditInteractor       Reads the current profile and saves the edited one to ProfileStore.
// Presenter   AccountEditPresenter        Holds the draft, validates it, and decides what errors to show.
// Entity      UserProfile (see the Models folder).
// Router      AccountEditRouter           Builds the module in its own navigation controller, and dismisses it.

/// What the fields start with.
struct AccountEditForm: Equatable {
    var name: String
    var phone: String
    var email: String
    var emoji: String?
    var colorName: String
}

/// Everything about the form that changes as the person types or picks.
struct AccountEditState: Equatable {
    let avatar: AvatarView.Content
    let tint: UIColor
    let selectedEmoji: String?
    let selectedColorName: String
    let nameError: String?
    let phoneError: String?
    let emailError: String?
    let canSave: Bool
    /// True once anything differs from the saved profile, so a swipe down can't quietly throw edits away.
    let isDirty: Bool
}

@MainActor
protocol AccountEditViewProtocol: AnyObject {
    func showForm(_ form: AccountEditForm, title: String, emojiChoices: [String?], colorNames: [String])
    func update(_ state: AccountEditState)
}

@MainActor
protocol AccountEditPresenterProtocol: AnyObject {
    func viewDidLoad()
    func nameDidChange(_ text: String)
    func phoneDidChange(_ text: String)
    func emailDidChange(_ text: String)
    func didSelectEmoji(_ emoji: String?)
    func didSelectColor(_ name: String)
    func didTapSave()
    func didTapCancel()
}

@MainActor
protocol AccountEditInteractorInputProtocol: AnyObject {
    var currentProfile: UserProfile? { get }
    func save(_ profile: UserProfile)
}

@MainActor
protocol AccountEditRouterProtocol: AnyObject {
    func dismiss()
}
