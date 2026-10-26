import UIKit

/// Brand pill pinned above the tab bar: item count, title and total. The caller hides it when the cart is empty.
final class StickyCartBar: UIControl {

    var onTap: (() -> Void)?

    private let countLabel = InsetLabel()
    private let titleLabel = UILabel.ds(font: DS.Font.headline, color: DS.Color.onBrand)
    private let totalLabel = UILabel.ds(font: DS.Font.headline, color: DS.Color.onBrand)
    private var itemCount = 0
    private var title = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? DS.Color.brandPressed : DS.Color.brand }
    }

    private func setUp() {
        backgroundColor = DS.Color.brand
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 3)

        countLabel.font = DS.Font.headline
        countLabel.adjustsFontForContentSizeCategory = true
        countLabel.textColor = DS.Color.onBrand
        countLabel.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        countLabel.textAlignment = .center
        countLabel.contentInsets = UIEdgeInsets(top: DS.Spacing.xs, left: DS.Spacing.s, bottom: DS.Spacing.xs, right: DS.Spacing.s)
        countLabel.setContentHuggingPriority(.required, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        countLabel.widthAnchor.constraint(greaterThanOrEqualTo: countLabel.heightAnchor).isActive = true

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        totalLabel.textAlignment = .natural
        totalLabel.setContentHuggingPriority(.required, for: .horizontal)
        totalLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let root = AdaptiveStackView([countLabel, titleLabel, totalLabel])
        root.isUserInteractionEnabled = false
        addSubview(root)
        root.pin(to: self, insets: UIEdgeInsets(top: DS.Spacing.m, left: DS.Spacing.l, bottom: DS.Spacing.m, right: DS.Spacing.l))
        heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
        isAccessibilityElement = true
        accessibilityTraits = .button
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.updateTexts()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.height / 2, 28)
    }

    func configure(itemCount: Int, totalText: String, title: String = "View cart") {
        self.itemCount = itemCount
        self.title = title
        totalLabel.text = totalText
        accessibilityLabel = "\(title), \(itemCount) \(itemCount == 1 ? "item" : "items"), \(totalText)"
        updateTexts()
    }

    /// At accessibility sizes the count badge would eat a whole row, so the count joins the title instead.
    private func updateTexts() {
        let compact = traitCollection.usesAccessibilityLayout
        countLabel.isHidden = compact
        countLabel.text = "\(itemCount)"
        titleLabel.text = compact ? "\(title) (\(itemCount))" : title
    }
}
