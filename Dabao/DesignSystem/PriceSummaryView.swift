import UIKit

/// One "title ... value" row. Stacks vertically at accessibility sizes.
private final class PriceRowView: UIView {

    init(title: String, value: String, titleFont: UIFont, valueFont: UIFont, color: UIColor) {
        super.init(frame: .zero)
        let titleLabel = UILabel.ds(font: titleFont, color: color)
        titleLabel.text = title
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let valueLabel = UILabel.ds(font: valueFont, color: color)
        valueLabel.text = value
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = AdaptiveStackView([titleLabel, valueLabel], spacing: DS.Spacing.s, alignment: .firstBaseline)
        addSubview(stack)
        stack.pin(to: self)

        isAccessibilityElement = true
        accessibilityLabel = "\(title), \(value)"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Subtotal / delivery / total card. It draws its own rounded surface: pin it with `DS.Spacing.l` side margins.
final class PriceSummaryView: UIView {

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        backgroundColor = DS.Color.surface
        layer.cornerRadius = DS.Radius.card
        layer.cornerCurve = .continuous

        stack.axis = .vertical
        stack.spacing = DS.Spacing.s
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.pin(to: self, insets: UIEdgeInsets(top: DS.Spacing.l, left: DS.Spacing.l, bottom: DS.Spacing.l, right: DS.Spacing.l))
    }

    func configure(rows: [(title: String, value: String)], totalTitle: String, totalValue: String) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for row in rows {
            stack.addArrangedSubview(PriceRowView(
                title: row.title, value: row.value,
                titleFont: DS.Font.subheadline, valueFont: DS.Font.subheadline, color: DS.Color.textSecondary
            ))
        }
        let separator = UIView()
        separator.backgroundColor = DS.Color.separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.isAccessibilityElement = false
        stack.addArrangedSubview(separator)
        stack.addArrangedSubview(PriceRowView(
            title: totalTitle, value: totalValue,
            titleFont: DS.Font.headline, valueFont: DS.Font.headline, color: DS.Color.textPrimary
        ))
    }
}
