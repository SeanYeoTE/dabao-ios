import UIKit

struct RestaurantCardModel: Hashable {
    let id: String
    let name: String
    let subtitle: String        // "Peranakan · Katong · $$"
    let ratingText: String      // "4.6"
    let reviewText: String      // "(1.2k)"
    let etaText: String         // "25 min"
    let feeText: String         // "$2.99 delivery"
    let symbolName: String
    let tint: UIColor
    let isOpen: Bool
    let tags: [String]
}

extension RestaurantCardModel {

    /// "★ 4.6 (1.2k) · 25 min · $2.99 delivery". The star is a text glyph so it follows dark mode.
    func metaText(font: UIFont) -> NSAttributedString {
        let rating = [ratingText, reviewText].filter { !$0.isEmpty }.joined(separator: " ")
        let parts = [rating, etaText, feeText].filter { !$0.isEmpty }
        let result = NSMutableAttributedString()
        if !ratingText.isEmpty {
            result.append(NSAttributedString(string: "★ ", attributes: [.font: font, .foregroundColor: DS.Color.warning]))
        }
        result.append(NSAttributedString(
            string: parts.joined(separator: " · "),
            attributes: [.font: font, .foregroundColor: DS.Color.textSecondary]
        ))
        return result
    }

    var tagsText: String? {
        let shown = tags.prefix(3)
        return shown.isEmpty ? nil : shown.joined(separator: " · ")
    }

    var accessibilityDescription: String {
        var parts = [name, subtitle]
        if !ratingText.isEmpty {
            let reviews = reviewText.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            parts.append(reviews.isEmpty ? "Rated \(ratingText)" : "Rated \(ratingText), \(reviews) reviews")
        }
        parts.append(contentsOf: [etaText, feeText].filter { !$0.isEmpty })
        if !isOpen { parts.append("Closed") }
        return parts.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

/// White rounded card: tinted symbol tile on the left, text on the right, "Closed" badge when shut.
final class RestaurantCardCell: CardTableViewCell {

    static let reuseIdentifier = "RestaurantCardCell"

    private let tile = SymbolTileView(side: 72)
    private let nameLabel = UILabel.ds(font: DS.Font.headline, color: DS.Color.textPrimary)
    private let subtitleLabel = UILabel.ds(font: DS.Font.footnote, color: DS.Color.textSecondary)
    private let metaLabel = UILabel.ds(font: DS.Font.footnote, color: DS.Color.textSecondary)
    private let tagsLabel = UILabel.ds(font: DS.Font.caption, color: DS.Color.brand)
    private let closedBadge = InsetLabel()
    private var model: RestaurantCardModel?

    override func setUpContent(in card: UIView) {
        closedBadge.text = "Closed"
        closedBadge.font = DS.Font.caption
        closedBadge.adjustsFontForContentSizeCategory = true
        closedBadge.textColor = DS.Color.danger
        closedBadge.backgroundColor = DS.Color.separator
        closedBadge.numberOfLines = 0
        closedBadge.isHidden = true

        let textStack = UIStackView(arrangedSubviews: [closedBadge, nameLabel, subtitleLabel, metaLabel, tagsLabel])
        textStack.axis = .vertical
        textStack.spacing = DS.Spacing.xs
        textStack.alignment = .leading

        let root = AdaptiveStackView([tile, textStack], alignment: .top)
        card.addSubview(root)
        root.pin(to: card, insets: UIEdgeInsets(top: DS.Spacing.m, left: DS.Spacing.m, bottom: DS.Spacing.m, right: DS.Spacing.m))
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        isAccessibilityElement = true
        accessibilityTraits = .button
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            if let model = self.model { self.metaLabel.attributedText = model.metaText(font: DS.Font.footnote) }
        }
    }

    func configure(_ model: RestaurantCardModel) {
        self.model = model
        tile.configure(symbolName: model.symbolName, tint: model.tint)
        tile.alpha = model.isOpen ? 1 : 0.45
        nameLabel.text = model.name
        nameLabel.textColor = model.isOpen ? DS.Color.textPrimary : DS.Color.textSecondary
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle.isEmpty
        metaLabel.attributedText = model.metaText(font: DS.Font.footnote)
        tagsLabel.text = model.tagsText
        tagsLabel.isHidden = model.tagsText == nil
        closedBadge.isHidden = model.isOpen
        accessibilityLabel = model.accessibilityDescription
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tile.alpha = 1
    }
}
