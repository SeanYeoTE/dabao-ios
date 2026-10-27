import UIKit

struct ProfileHeaderModel: Equatable {
    let avatar: AvatarView.Content
    let tint: UIColor
    /// "Aisha Tan", or "Guest".
    let title: String
    /// "+65 9123 4567 · aisha@example.com". nil hides the line.
    let subtitle: String?
    let showsAddDetailsButton: Bool
}

/// The top of the Account page: a big avatar, the name and contact details, and an optional "Add your details" button.
/// Self-sizing; use it as a table header and resize it after layout.
final class ProfileHeaderView: UIView {

    var onAddDetails: (() -> Void)?

    private let avatarView = AvatarView(size: .large)
    private let titleLabel = UILabel.ds(font: DS.Font.title2, color: DS.Color.textPrimary)
    private let subtitleLabel = UILabel.ds(font: DS.Font.subheadline, color: DS.Color.textSecondary)
    private let textGroup = UIView()
    private let addButton = PrimaryButton(title: "Add your details")

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.textAlignment = .center
        subtitleLabel.textAlignment = .center

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = DS.Spacing.xs
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textGroup.translatesAutoresizingMaskIntoConstraints = false
        textGroup.addSubview(textStack)
        textStack.pin(to: textGroup)
        // Name and contact details are read together.
        textGroup.isAccessibilityElement = true
        textGroup.accessibilityTraits = .header

        addButton.addAction(UIAction { [weak self] _ in self?.onAddDetails?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [avatarView, textGroup, addButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = DS.Spacing.m
        stack.setCustomSpacing(DS.Spacing.l, after: textGroup)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: DS.Spacing.l),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DS.Spacing.s),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DS.Spacing.l),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DS.Spacing.l),
            textGroup.widthAnchor.constraint(equalTo: stack.widthAnchor),
            addButton.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ model: ProfileHeaderModel) {
        avatarView.configure(content: model.avatar, tint: model.tint)
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil
        addButton.isHidden = !model.showsAddDetailsButton
        textGroup.accessibilityLabel = [model.title, model.subtitle].compactMap { $0 }.joined(separator: ", ")
    }
}
