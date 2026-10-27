import UIKit

/// Top of the tracking screen: restaurant tile, name, a large ETA, the arrival time and the stage timeline.
final class OrderTrackingHeaderView: UIView {

    private let tile = SymbolTileView(side: 72)
    private let nameLabel = UILabel.ds(font: DS.Font.headline, color: DS.Color.textSecondary)
    private let etaLabel = UILabel.ds(font: DS.Font.largeTitle, color: DS.Color.textPrimary)
    private let arrivalLabel = UILabel.ds(font: DS.Font.subheadline, color: DS.Color.textSecondary)
    private let timeline = DeliveryTimelineView()
    private let hero = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        for label in [nameLabel, etaLabel, arrivalLabel] {
            label.textAlignment = .center
        }
        for view in [tile, nameLabel, etaLabel, arrivalLabel] {
            hero.addArrangedSubview(view)
        }
        hero.axis = .vertical
        hero.alignment = .center
        hero.spacing = DS.Spacing.xs
        hero.setCustomSpacing(DS.Spacing.m, after: tile)
        hero.setCustomSpacing(DS.Spacing.s, after: etaLabel)
        for label in [nameLabel, etaLabel, arrivalLabel] {
            label.widthAnchor.constraint(lessThanOrEqualTo: hero.widthAnchor).isActive = true
        }

        let root = UIStackView(arrangedSubviews: [hero, timeline])
        root.axis = .vertical
        root.alignment = .fill
        root.spacing = DS.Spacing.xl
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)
        root.pin(to: self, insets: UIEdgeInsets(top: DS.Spacing.xl, left: DS.Spacing.l, bottom: DS.Spacing.l, right: DS.Spacing.l))

        hero.isAccessibilityElement = true
        hero.accessibilityTraits = .header
    }

    func configure(_ header: OrderTrackingHeaderViewModel) {
        tile.configure(symbolName: header.symbolName, tint: UIColor(hex: header.colorHex))
        nameLabel.text = header.restaurantName
        etaLabel.text = header.etaText
        etaLabel.textColor = header.isDelivered ? DS.Color.success : DS.Color.textPrimary
        arrivalLabel.text = header.arrivalText
        hero.accessibilityLabel = "\(header.restaurantName), \(header.etaText), \(header.arrivalText)"
    }

    func configureTimeline(_ model: OrderTrackingTimelineViewModel, animated: Bool) {
        timeline.configure(stages: model.stages, currentIndex: model.currentIndex, animated: animated)
    }
}
