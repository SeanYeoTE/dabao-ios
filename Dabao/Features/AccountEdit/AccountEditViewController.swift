import UIKit

/// The edit-profile form. It sends every change to the presenter and shows whatever state comes back.
final class AccountEditViewController: UIViewController {

    var presenter: AccountEditPresenterProtocol!

    private static let emojiNames: [String: String] = [
        "🍜": "Noodles", "🍛": "Curry", "🍗": "Chicken", "🥟": "Dumpling",
        "🧋": "Bubble tea", "🌶️": "Chilli", "🍰": "Cake",
    ]

    private let scrollView = UIScrollView()
    private let avatarView = AvatarView(size: .large)
    private let emojiRow = UIStackView()
    private let colorRow = UIStackView()
    private let nameField = FormFieldView(label: "Name", placeholder: "Your name",
                                          textContentType: .name, autocapitalization: .words)
    private let phoneField = FormFieldView(label: "Phone (+65)", placeholder: "9123 4567",
                                           keyboardType: .phonePad, textContentType: .telephoneNumber)
    private let emailField = FormFieldView(label: "Email", placeholder: "you@example.com",
                                           keyboardType: .emailAddress, textContentType: .emailAddress,
                                           autocapitalization: .none)
    private lazy var saveButton = UIBarButtonItem(title: "Save", primaryAction: UIAction { [weak self] _ in
        self?.view.endEditing(true)
        self?.presenter.didTapSave()
    })

    private var emojiButtons: [(emoji: String?, button: UIButton)] = []
    private var colorButtons: [(name: String, button: UIButton)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.Color.background
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.presenter.didTapCancel()
        })
        saveButton.style = .done
        navigationItem.rightBarButtonItem = saveButton
        setUpLayout()

        nameField.onTextChange = { [weak self] in self?.presenter.nameDidChange($0) }
        phoneField.onTextChange = { [weak self] in self?.presenter.phoneDidChange($0) }
        emailField.onTextChange = { [weak self] in self?.presenter.emailDidChange($0) }
        presenter.viewDidLoad()
    }

    private func setUpLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        emojiRow.spacing = DS.Spacing.s
        colorRow.spacing = DS.Spacing.s
        let emojiScroller = horizontalScroller(for: emojiRow)
        let colorScroller = horizontalScroller(for: colorRow)

        // The avatar keeps its fixed size, centred in the full-width stack.
        let avatarHolder = UIView()
        avatarHolder.translatesAutoresizingMaskIntoConstraints = false
        avatarHolder.addSubview(avatarView)

        let stack = UIStackView(arrangedSubviews: [
            avatarHolder,
            sectionLabel("Emoji"), emojiScroller,
            sectionLabel("Colour"), colorScroller,
            nameField, phoneField, emailField,
        ])
        stack.axis = .vertical
        stack.spacing = DS.Spacing.m
        stack.alignment = .fill
        stack.setCustomSpacing(DS.Spacing.xl, after: avatarHolder)
        stack.setCustomSpacing(DS.Spacing.l, after: emojiScroller)
        stack.setCustomSpacing(DS.Spacing.xl, after: colorScroller)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Ends at the keyboard, so the focused field can always be scrolled into view.
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: DS.Spacing.l),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -DS.Spacing.xl),
            stack.leadingAnchor.constraint(equalTo: frame.leadingAnchor, constant: DS.Spacing.l),
            stack.trailingAnchor.constraint(equalTo: frame.trailingAnchor, constant: -DS.Spacing.l),

            avatarView.topAnchor.constraint(equalTo: avatarHolder.topAnchor),
            avatarView.bottomAnchor.constraint(equalTo: avatarHolder.bottomAnchor),
            avatarView.centerXAnchor.constraint(equalTo: avatarHolder.centerXAnchor),
        ])
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let label = UILabel.ds(font: DS.Font.footnote, color: DS.Color.textSecondary)
        label.text = text
        label.accessibilityTraits = .header
        return label
    }

    private func horizontalScroller(for row: UIStackView) -> UIScrollView {
        let scroller = UIScrollView()
        scroller.showsHorizontalScrollIndicator = false
        scroller.translatesAutoresizingMaskIntoConstraints = false
        row.translatesAutoresizingMaskIntoConstraints = false
        scroller.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: scroller.contentLayoutGuide.topAnchor, constant: DS.Spacing.xxs),
            row.bottomAnchor.constraint(equalTo: scroller.contentLayoutGuide.bottomAnchor, constant: -DS.Spacing.xxs),
            row.leadingAnchor.constraint(equalTo: scroller.contentLayoutGuide.leadingAnchor, constant: DS.Spacing.xxs),
            row.trailingAnchor.constraint(equalTo: scroller.contentLayoutGuide.trailingAnchor, constant: -DS.Spacing.xxs),
            scroller.frameLayoutGuide.heightAnchor.constraint(equalTo: row.heightAnchor, constant: 2 * DS.Spacing.xxs),
        ])
        return scroller
    }

    private func makeChoiceButton(diameter: CGFloat, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = diameter / 2
        button.layer.cornerCurve = .circular
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: diameter),
            button.heightAnchor.constraint(equalToConstant: diameter),
        ])
        return button
    }

    private func updateBorders() {
        let brand = DS.Color.brand.resolvedColor(with: traitCollection).cgColor
        for (_, button) in emojiButtons {
            button.layer.borderColor = brand
        }
    }
}

extension AccountEditViewController: AccountEditViewProtocol {

    func showForm(_ form: AccountEditForm, title: String, emojiChoices: [String?], colorNames: [String]) {
        self.title = title
        nameField.text = form.name
        phoneField.text = form.phone
        emailField.text = form.email

        let diameter = max(DS.minTapTarget, 48)
        emojiButtons = emojiChoices.map { emoji in
            let button = makeChoiceButton(diameter: diameter) { [weak self] in self?.presenter.didSelectEmoji(emoji) }
            button.backgroundColor = DS.Color.surface
            if let emoji {
                button.setTitle(emoji, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 26)
                button.accessibilityLabel = Self.emojiNames[emoji] ?? emoji
            } else {
                button.setTitle("None", for: .normal)
                button.setTitleColor(DS.Color.textSecondary, for: .normal)
                button.titleLabel?.font = DS.Font.caption
                // The circle has a fixed size, so the word shrinks to fit at large text sizes instead of becoming "…".
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.titleLabel?.minimumScaleFactor = 0.3
                button.titleEdgeInsets = UIEdgeInsets(top: 0, left: DS.Spacing.xs, bottom: 0, right: DS.Spacing.xs)
                button.accessibilityLabel = "No emoji, use initials"
            }
            emojiRow.addArrangedSubview(button)
            return (emoji, button)
        }
        colorButtons = colorNames.map { name in
            let button = makeChoiceButton(diameter: diameter) { [weak self] in self?.presenter.didSelectColor(name) }
            button.backgroundColor = DS.AvatarPalette.color(named: name)
            button.tintColor = .white
            button.accessibilityLabel = name.capitalized
            colorRow.addArrangedSubview(button)
            return (name, button)
        }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateBorders()
        }
        updateBorders()
    }

    func update(_ state: AccountEditState) {
        avatarView.configure(content: state.avatar, tint: state.tint)
        nameField.setError(state.nameError)
        phoneField.setError(state.phoneError)
        emailField.setError(state.emailError)
        saveButton.isEnabled = state.canSave
        isModalInPresentation = state.isDirty

        for (emoji, button) in emojiButtons {
            let selected = emoji == state.selectedEmoji
            button.layer.borderWidth = selected ? 2 : 0
            button.accessibilityTraits = selected ? [.button, .selected] : .button
        }
        let check = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        for (name, button) in colorButtons {
            let selected = name == state.selectedColorName
            button.setImage(selected ? check : nil, for: .normal)
            button.accessibilityTraits = selected ? [.button, .selected] : .button
        }
    }
}
