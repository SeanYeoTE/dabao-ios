import UIKit

/// Keeps the draft profile, validates it on every change, and saves it when it's valid.
@MainActor
final class AccountEditPresenter: AccountEditPresenterProtocol {

    /// nil is "None": show the initials.
    static let emojiChoices: [String?] = [nil, "🍜", "🍛", "🍗", "🥟", "🧋", "🌶️", "🍰"]

    weak var view: AccountEditViewProtocol?
    private let interactor: AccountEditInteractorInputProtocol
    private let router: AccountEditRouterProtocol

    private var original = AccountEditForm(name: "", phone: "", email: "", emoji: nil, colorName: AvatarColor.pink.rawValue)
    private var draft = AccountEditForm(name: "", phone: "", email: "", emoji: nil, colorName: AvatarColor.pink.rawValue)
    /// The name error waits until the person has typed in the field, so a new guest isn't greeted by red text.
    private var nameEdited = false

    init(view: AccountEditViewProtocol, interactor: AccountEditInteractorInputProtocol, router: AccountEditRouterProtocol) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    // MARK: AccountEditPresenterProtocol (from the view)

    func viewDidLoad() {
        let profile = interactor.currentProfile
        if let profile {
            original = AccountEditForm(name: profile.name,
                                       phone: ProfileValidator.formattedPhone(profile.phone)
                                           .replacingOccurrences(of: "+65 ", with: ""),
                                       email: profile.email,
                                       emoji: profile.avatarEmoji,
                                       colorName: profile.avatarColor.rawValue)
        }
        draft = original
        view?.showForm(draft, title: profile == nil ? "Your details" : "Edit profile",
                       emojiChoices: Self.emojiChoices, colorNames: AvatarColor.allCases.map(\.rawValue))
        publish()
    }

    func nameDidChange(_ text: String) {
        draft.name = text
        nameEdited = true
        publish()
    }

    func phoneDidChange(_ text: String) {
        draft.phone = text
        publish()
    }

    func emailDidChange(_ text: String) {
        draft.email = text
        publish()
    }

    func didSelectEmoji(_ emoji: String?) {
        draft.emoji = emoji
        publish()
    }

    func didSelectColor(_ name: String) {
        draft.colorName = name
        publish()
    }

    func didTapSave() {
        guard isValid, let color = AvatarColor(rawValue: draft.colorName) else { return }
        interactor.save(UserProfile(name: draft.name, phone: draft.phone, email: draft.email,
                                    avatarEmoji: draft.emoji, avatarColor: color))
        router.dismiss()
    }

    func didTapCancel() {
        router.dismiss()
    }

    // MARK: - State

    private var isValid: Bool {
        ProfileValidator.validateName(draft.name) == nil
            && ProfileValidator.validatePhone(draft.phone) == nil
            && ProfileValidator.validateEmail(draft.email) == nil
    }

    func makeState() -> AccountEditState {
        let nameError = ProfileValidator.validateName(draft.name)
        let showNameError = nameError == .nameTooLong || (nameError != nil && nameEdited)
        let initials = UserProfile(name: draft.name, phone: "", email: "", avatarEmoji: nil, avatarColor: .pink).initials
        let avatar: AvatarView.Content = draft.emoji.map { .emoji($0) }
            ?? (initials.isEmpty ? .symbol("person.fill") : .initials(initials))
        return AccountEditState(
            avatar: avatar,
            tint: DS.AvatarPalette.color(named: draft.colorName),
            selectedEmoji: draft.emoji,
            selectedColorName: draft.colorName,
            nameError: showNameError ? nameError.map(ProfileValidator.message(for:)) : nil,
            phoneError: ProfileValidator.validatePhone(draft.phone).map(ProfileValidator.message(for:)),
            emailError: ProfileValidator.validateEmail(draft.email).map(ProfileValidator.message(for:)),
            canSave: isValid,
            isDirty: draft != original
        )
    }

    private func publish() {
        view?.update(makeState())
    }
}
