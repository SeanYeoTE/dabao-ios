import UIKit

struct StatItem: Hashable {
    let value: String
    let label: String
    let symbolName: String
}

/// A row of equal-width stat tiles. At accessibility text sizes the tiles stack vertically.
final class StatsRowView: UIView {

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = DS.Spacing.s
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.pin(to: self)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.applyAxis()
        }
        applyAxis()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ items: [StatItem]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        items.map(StatTileView.init).forEach(stack.addArrangedSubview)
    }

    private func applyAxis() {
        stack.axis = traitCollection.usesAccessibilityLayout ? .vertical : .horizontal
    }
}

/// One tile: symbol, value, label. VoiceOver reads it as "label, value".
private final class StatTileView: UIView {

    init(_ item: StatItem) {
        super.init(frame: .zero)
        backgroundColor = DS.Color.surfaceElevated
        layer.cornerRadius = DS.Radius.small
        layer.cornerCurve = .continuous

        let icon = UIImageView(image: UIImage(systemName: item.symbolName))
        icon.tintColor = DS.Color.brand
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(font: DS.Font.headline)
        icon.adjustsImageSizeForAccessibilityContentSizeCategory = true
        icon.contentMode = .left
        icon.setContentHuggingPriority(.required, for: .vertical)

        // Long restaurant names get three lines and may shrink a little so a long word fits the narrow tile,
        // then end in an ellipsis rather than a clipped word.
        let value = UILabel.ds(font: DS.Font.headline, color: DS.Color.textPrimary, lines: 3)
        value.lineBreakMode = .byTruncatingTail
        value.adjustsFontSizeToFitWidth = true
        value.minimumScaleFactor = 0.75
        value.text = item.value
        let label = UILabel.ds(font: DS.Font.caption, color: DS.Color.textSecondary)
        label.text = item.label

        let column = UIStackView(arrangedSubviews: [icon, value, label])
        column.axis = .vertical
        column.alignment = .leading
        column.spacing = DS.Spacing.xs
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)
        column.pin(to: self, insets: UIEdgeInsets(top: DS.Spacing.m, left: DS.Spacing.m,
                                                  bottom: DS.Spacing.m, right: DS.Spacing.m))

        isAccessibilityElement = true
        accessibilityLabel = "\(item.label), \(item.value)"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
