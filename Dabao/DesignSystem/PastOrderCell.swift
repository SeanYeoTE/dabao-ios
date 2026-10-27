import UIKit

struct RatingFooterModel: Hashable {
    let title: String           // "Tap to rate" | "You rated"
    let subtitle: String?       // "by 30 Oct 2026" | "Change by 30 Oct 2026" | nil
    let rating: Int?
    let isEditable: Bool
}

struct PastOrderCellModel: Hashable {
    let id: UUID
    let restaurantName: String
    let totalText: String
    let dateText: String        // "Delivered on 25 Oct, 21:27"
    let itemsSummary: String
    let symbolName: String
    let tint: UIColor
    let footer: RatingFooterModel?
}

/// A delivered order: tile, name and total, delivery date, items, a Reorder button and the rating footer.
/// The card body, the button and the stars are three separate tap targets (and VoiceOver elements).
final class PastOrderCell: CardTableViewCell {

    static let reuseIdentifier = "PastOrderCell"

    var onReorder: (() -> Void)?
    var onRate: ((Int) -> Void)?
    /// A tap on the card body: anywhere above the Reorder button.
    var onSelectBody: (() -> Void)?

    private let body = CardBodyControl()
    private let tile = SymbolTileView(side: 64)
    private let nameLabel = UILabel.ds(font: DS.Font.headline, color: DS.Color.textPrimary, lines: 2)
    private let totalLabel = UILabel.ds(font: DS.Font.headline, color: DS.Color.textPrimary, lines: 1)
    private let dateLabel = UILabel.ds(font: DS.Font.footnote, color: DS.Color.textSecondary)
    private let itemsLabel = UILabel.ds(font: DS.Font.callout, color: DS.Color.textSecondary, lines: 2)
    private let reorderButton = PrimaryButton(title: "Reorder")
    private let divider = UIView()
    private let footer = UIView()
    private let footerTitleLabel = UILabel.ds(font: DS.Font.subheadline, color: DS.Color.textSecondary)
    private let footerSubtitleLabel = UILabel.ds(font: DS.Font.subheadline, color: DS.Color.textSecondary)
    private let stars = StarRatingView()

    override func setUpContent(in card: UIView) {
        // Header: name and total share a row; they stack at accessibility sizes.
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        totalLabel.textAlignment = .right
        totalLabel.setContentHuggingPriority(.required, for: .horizontal)
        totalLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let header = AdaptiveStackView([nameLabel, totalLabel], spacing: DS.Spacing.s, alignment: .top)

        itemsLabel.lineBreakMode = .byTruncatingTail
        let textStack = UIStackView(arrangedSubviews: [header, dateLabel, itemsLabel])
        textStack.axis = .vertical
        textStack.spacing = DS.Spacing.xs
        textStack.setCustomSpacing(DS.Spacing.s, after: dateLabel)

        let bodyStack = AdaptiveStackView([tile, textStack], spacing: DS.Spacing.m, alignment: .top)
        bodyStack.isUserInteractionEnabled = false
        body.translatesAutoresizingMaskIntoConstraints = false
        body.addSubview(bodyStack)
        bodyStack.pin(to: body)
        body.addAction(UIAction { [weak self] _ in self?.onSelectBody?() }, for: .touchUpInside)

        reorderButton.addAction(UIAction { [weak self] _ in self?.onReorder?() }, for: .touchUpInside)

        let top = UIStackView(arrangedSubviews: [body, reorderButton])
        top.axis = .vertical
        top.spacing = DS.Spacing.l
        top.isLayoutMarginsRelativeArrangement = true
        top.directionalLayoutMargins = NSDirectionalEdgeInsets(top: DS.Spacing.l, leading: DS.Spacing.l,
                                                               bottom: DS.Spacing.l, trailing: DS.Spacing.l)

        divider.backgroundColor = DS.Color.separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        footerTitleLabel.font = UIFontMetrics(forTextStyle: .subheadline)
            .scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        let footerText = UIStackView(arrangedSubviews: [footerTitleLabel, footerSubtitleLabel])
        footerText.axis = .vertical
        footerText.spacing = DS.Spacing.xxs
        footerText.isAccessibilityElement = false
        footerText.setContentHuggingPriority(.defaultLow, for: .horizontal)
        footerText.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stars.setContentHuggingPriority(.required, for: .horizontal)
        stars.setContentCompressionResistancePriority(.required, for: .horizontal)
        stars.onSelect = { [weak self] value in self?.onRate?(value) }
        let footerRow = AdaptiveStackView([footerText, stars], spacing: DS.Spacing.m, alignment: .center)
        footer.addSubview(footerRow)
        footerRow.pin(to: footer, insets: UIEdgeInsets(top: DS.Spacing.s, left: DS.Spacing.l,
                                                       bottom: DS.Spacing.s, right: DS.Spacing.s))

        let root = UIStackView(arrangedSubviews: [top, divider, footer])
        root.axis = .vertical
        root.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(root)
        root.pin(to: card)
        divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true

        // The cell itself isn't an element: VoiceOver visits the body, the button, then the stars.
        isAccessibilityElement = false
        body.isAccessibilityElement = true
        body.accessibilityTraits = .button
        accessibilityElements = [body, reorderButton, footerText, stars]

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.applyTextLimits()
        }
        applyTextLimits()
    }

    func configure(_ model: PastOrderCellModel) {
        tile.configure(symbolName: model.symbolName, tint: model.tint)
        nameLabel.text = model.restaurantName
        totalLabel.text = model.totalText
        dateLabel.text = model.dateText
        itemsLabel.text = model.itemsSummary
        itemsLabel.isHidden = model.itemsSummary.isEmpty
        body.accessibilityLabel = [model.restaurantName, model.dateText, model.itemsSummary, "Total \(model.totalText)"]
            .filter { !$0.isEmpty }.joined(separator: ", ")
        reorderButton.accessibilityLabel = "Reorder from \(model.restaurantName)"

        if let rating = model.footer {
            footerTitleLabel.text = rating.title
            footerSubtitleLabel.text = rating.subtitle
            footerSubtitleLabel.isHidden = (rating.subtitle ?? "").isEmpty
            let deadline = rating.subtitle.flatMap { $0.components(separatedBy: "by ").last }
            stars.configure(rating: rating.rating, isEditable: rating.isEditable, deadlineText: deadline)
            divider.isHidden = false
            footer.isHidden = false
            accessibilityElements = [body, reorderButton, stars]
        } else {
            divider.isHidden = true
            footer.isHidden = true
            accessibilityElements = [body, reorderButton]
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onReorder = nil
        onRate = nil
        onSelectBody = nil
    }

    // The body shows its own pressed state, so a tap on the button or stars doesn't flash the whole card.
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}

    private func applyTextLimits() {
        // At accessibility sizes, show everything rather than truncating to two lines.
        let lines = traitCollection.usesAccessibilityLayout ? 0 : 2
        nameLabel.numberOfLines = lines
        itemsLabel.numberOfLines = lines
    }
}

/// The tappable top part of a past order card. Dims while pressed.
private final class CardBodyControl: UIControl {

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.5 : 1 }
    }

    override func accessibilityActivate() -> Bool {
        sendActions(for: .touchUpInside)
        return true
    }
}
