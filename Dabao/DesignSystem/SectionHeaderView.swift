import UIKit

final class SectionHeaderView: UITableViewHeaderFooterView {

    static let reuseIdentifier = "SectionHeaderView"

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
    }
}
