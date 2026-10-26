import UIKit

/// Top of a receipt: restaurant tile, name and when the order was placed. Read-only.
final class ReceiptHeaderView: UIView {

    private let tile = SymbolTileView(side: 72)
    private let nameLabel = UILabel.ds(font: DS.Font.title2, color: DS.Color.textPrimary)
    private let dateLabel = UILabel.ds(font: DS.Font.subheadline, color: DS.Color.textSecondary)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        nameLabel.textAlignment = .center
        dateLabel.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [tile, nameLabel, dateLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = DS.Spacing.s
        stack.setCustomSpacing(DS.Spacing.m, after: tile)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.pin(to: self, insets: UIEdgeInsets(top: DS.Spacing.xl, left: DS.Spacing.l, bottom: DS.Spacing.l, right: DS.Spacing.l))
        nameLabel.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor).isActive = true
        dateLabel.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor).isActive = true

        isAccessibilityElement = true
        accessibilityTraits = .header
    }

    func configure(restaurantName: String, dateText: String, symbolName: String, tint: UIColor) {
        tile.configure(symbolName: symbolName, tint: tint)
        nameLabel.text = restaurantName
        dateLabel.text = dateText
        accessibilityLabel = "Receipt from \(restaurantName), \(dateText)"
    }
}

/// One receipt line: "2×  Chicken Rice  $7.00" with optional notes under the name.
final class ReceiptLineCell: UITableViewCell {

    static let reuseIdentifier = "ReceiptLineCell"

    private let quantityLabel = UILabel.ds(font: DS.Font.bodyBold, color: DS.Color.brand, lines: 1)
    private let nameLabel = UILabel.ds(font: DS.Font.body, color: DS.Color.textPrimary)
    private let notesLabel = UILabel.ds(font: DS.Font.footnote, color: DS.Color.textSecondary)
    private let priceLabel = UILabel.ds(font: DS.Font.body, color: DS.Color.textPrimary, lines: 1)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = DS.Color.surface
        selectionStyle = .none

        quantityLabel.setContentHuggingPriority(.required, for: .horizontal)
        quantityLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        quantityLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, notesLabel])
        textStack.axis = .vertical
        textStack.spacing = DS.Spacing.xs
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let root = AdaptiveStackView([quantityLabel, textStack, priceLabel], alignment: .firstBaseline)
        contentView.addSubview(root)
        root.pin(to: contentView, insets: UIEdgeInsets(top: DS.Spacing.m, left: DS.Spacing.l, bottom: DS.Spacing.m, right: DS.Spacing.l))

        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(quantityText: String, name: String, notes: String?, priceText: String) {
        quantityLabel.text = quantityText
        nameLabel.text = name
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        notesLabel.text = trimmedNotes
        notesLabel.isHidden = trimmedNotes.isEmpty
        priceLabel.text = priceText
        let spokenQuantity = quantityText.replacingOccurrences(of: "×", with: " times")
        accessibilityLabel = [
            "\(spokenQuantity) \(name)",
            trimmedNotes.isEmpty ? nil : "Note: \(trimmedNotes)",
            priceText
        ].compactMap { $0 }.joined(separator: ", ")
    }
}
