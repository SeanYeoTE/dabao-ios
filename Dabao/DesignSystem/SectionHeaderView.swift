import UIKit

final class SectionHeaderView: UITableViewHeaderFooterView {

    static let reuseIdentifier = "SectionHeaderView"

    private var lastWidth: CGFloat = 0
    private let titleLabel = UILabel.ds(font: DS.Font.title2, color: DS.Color.textPrimary)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        // Opaque so rows don't show through a pinned header.
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = DS.Color.background
        backgroundConfiguration = background

        titleLabel.accessibilityTraits = .header
        contentView.addSubview(titleLabel)
        titleLabel.pin(to: contentView, insets: UIEdgeInsets(
            top: DS.Spacing.l, left: DS.Spacing.l, bottom: DS.Spacing.s, right: DS.Spacing.l
        ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
        invalidateIntrinsicContentSize()
    }

    // Lets the header also work outside a table (for example inside a stack in a table header), where it has no row height.
    override var intrinsicContentSize: CGSize {
        let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
        let textWidth = max(width - 2 * DS.Spacing.l, 1)
        let textHeight = titleLabel.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(textHeight) + DS.Spacing.l + DS.Spacing.s)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width != lastWidth {
            lastWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }
}
