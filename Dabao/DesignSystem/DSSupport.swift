import UIKit

extension UITraitCollection {
    /// True from AX1 upwards, where components stack vertically instead of squeezing a row.
    var usesAccessibilityLayout: Bool { preferredContentSizeCategory.isAccessibilityCategory }
}

/// A stack that is horizontal normally and vertical at accessibility text sizes.
final class AdaptiveStackView: UIStackView {

    private let regularAlignment: UIStackView.Alignment
    private let accessibilityAlignment: UIStackView.Alignment

    init(
        _ views: [UIView],
        spacing: CGFloat = DS.Spacing.m,
        alignment: UIStackView.Alignment = .center,
        accessibilityAlignment: UIStackView.Alignment = .leading
    ) {
        regularAlignment = alignment
        self.accessibilityAlignment = accessibilityAlignment
        super.init(frame: .zero)
        views.forEach(addArrangedSubview)
        self.spacing = spacing
        translatesAutoresizingMaskIntoConstraints = false
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.applyLayout()
        }
        applyLayout()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyLayout()
    }

    private func applyLayout() {
        let vertical = traitCollection.usesAccessibilityLayout
        axis = vertical ? .vertical : .horizontal
        alignment = vertical ? accessibilityAlignment : regularAlignment
    }
}

/// A label with padding, used for badges.
final class InsetLabel: UILabel {

    var contentInsets = UIEdgeInsets(top: DS.Spacing.xs, left: DS.Spacing.s, bottom: DS.Spacing.xs, right: DS.Spacing.s) {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let inner = super.textRect(forBounds: bounds.inset(by: contentInsets), limitedToNumberOfLines: numberOfLines)
        return inner.inset(by: UIEdgeInsets(
            top: -contentInsets.top, left: -contentInsets.left, bottom: -contentInsets.bottom, right: -contentInsets.right
        ))
    }

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(
            width: base.width + contentInsets.left + contentInsets.right,
            height: base.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}

/// A rounded tile with a tinted SF Symbol. Decorative: VoiceOver reads the text next to it.
final class SymbolTileView: UIView {

    private let imageView = UIImageView()
    private let side: CGFloat

    init(side: CGFloat) {
        self.side = side
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = side >= 56 ? DS.Radius.card : DS.Radius.small
        layer.cornerCurve = .continuous
        isAccessibilityElement = false

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: side),
            heightAnchor.constraint(equalToConstant: side),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: side * 0.55),
            imageView.heightAnchor.constraint(equalToConstant: side * 0.55)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(symbolName: String, tint: UIColor) {
        let configuration = UIImage.SymbolConfiguration(pointSize: side * 0.4, weight: .semibold)
        imageView.image = UIImage(systemName: symbolName, withConfiguration: configuration)
            ?? UIImage(systemName: "fork.knife", withConfiguration: configuration)
        imageView.tintColor = tint
        backgroundColor = tint.withAlphaComponent(0.16)
    }
}

/// Base for the white rounded card rows. Subclasses build their content in `setUpContent(in:)`.
class CardTableViewCell: UITableViewCell {

    let cardView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        // Hides the separator: the cards provide their own spacing.
        separatorInset = UIEdgeInsets(top: 0, left: 10_000, bottom: 0, right: 0)

        cardView.backgroundColor = DS.Color.surface
        cardView.layer.cornerRadius = DS.Radius.card
        cardView.layer.cornerCurve = .continuous
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.s),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DS.Spacing.s),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.l),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.l)
        ])
        setUpContent(in: cardView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpContent(in card: UIView) {}

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        cardView.backgroundColor = highlighted ? DS.Color.separator : DS.Color.surface
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        cardView.backgroundColor = selected ? DS.Color.separator : DS.Color.surface
    }
}

extension UILabel {
    /// Wrapping, Dynamic Type label in one call.
    static func ds(font: UIFont, color: UIColor, lines: Int = 0) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        label.adjustsFontForContentSizeCategory = true
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}

extension UIView {
    func pin(to other: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom)
        ])
    }
}
