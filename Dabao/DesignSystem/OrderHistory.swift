import UIKit

struct OrderHistoryCellModel: Hashable {
    let id: UUID
    let restaurantName: String
    let dateText: String            // "Today, 6:42 PM"
    let itemsSummary: String        // "2 × Chicken Rice, 1 × Iced Tea"
    let totalText: String
    let symbolName: String
    let tint: UIColor
}

/// A past order as a white card: restaurant tile, name, date, items and total.
final class OrderHistoryCell: CardTableViewCell {

    static let reuseIdentifier = "OrderHistoryCell"

    private let tile = SymbolTileView(side: 56)
    private let nameLabel = UILabel.ds(font: DS.Font.headline, color: DS.Color.textPrimary)
    private let dateLabel = UILabel.ds(font: DS.Font.footnote, color: DS.Color.textSecondary)
    private let itemsLabel = UILabel.ds(font: DS.Font.subheadline, color: DS.Color.textSecondary)
    private let totalLabel = UILabel.ds(font: DS.Font.bodyBold, color: DS.Color.textPrimary, lines: 1)

    override func setUpContent(in card: UIView) {
        let textStack = UIStackView(arrangedSubviews: [nameLabel, dateLabel, itemsLabel])
        textStack.axis = .vertical
        textStack.spacing = DS.Spacing.xs
        textStack.alignment = .leading
        textStack.setCustomSpacing(DS.Spacing.s, after: dateLabel)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = DS.Color.textTertiary
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.isAccessibilityElement = false
        totalLabel.setContentHuggingPriority(.required, for: .horizontal)
        totalLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let trailing = UIStackView(arrangedSubviews: [totalLabel, chevron])
        trailing.axis = .horizontal
        trailing.spacing = DS.Spacing.s
        trailing.alignment = .center

        let root = AdaptiveStackView([tile, textStack, trailing], alignment: .top)
        card.addSubview(root)
        root.pin(to: card, insets: UIEdgeInsets(top: DS.Spacing.m, left: DS.Spacing.m, bottom: DS.Spacing.m, right: DS.Spacing.m))

        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    func configure(_ model: OrderHistoryCellModel) {
        tile.configure(symbolName: model.symbolName, tint: model.tint)
        nameLabel.text = model.restaurantName
        dateLabel.text = model.dateText
        itemsLabel.text = model.itemsSummary
        itemsLabel.isHidden = model.itemsSummary.isEmpty
        totalLabel.text = model.totalText
        accessibilityLabel = [model.restaurantName, model.dateText, model.itemsSummary, "Total \(model.totalText)"]
            .filter { !$0.isEmpty }.joined(separator: ", ")
    }
}
