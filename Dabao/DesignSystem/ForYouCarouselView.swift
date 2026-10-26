import UIKit

struct ForYouItem: Hashable {
    let card: RestaurantCardModel
    let reason: String?     // "Because you ordered Laksa"
}

private final class ForYouCardCell: UICollectionViewCell {

    private let tile = SymbolTileView(side: 48)
    private let closedBadge = InsetLabel()
    private let nameLabel = UILabel.ds(font: DS.Font.headline, color: DS.Color.textPrimary)
    private let subtitleLabel = UILabel.ds(font: DS.Font.footnote, color: DS.Color.textSecondary)
    private let metaLabel = UILabel.ds(font: DS.Font.footnote, color: DS.Color.textSecondary)
    private let reasonLabel = UILabel.ds(font: DS.Font.caption, color: DS.Color.brand)
    private var item: ForYouItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = DS.Color.surface
        contentView.layer.cornerRadius = DS.Radius.card
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true

        closedBadge.text = "Closed"
        closedBadge.font = DS.Font.caption
        closedBadge.adjustsFontForContentSizeCategory = true
        closedBadge.textColor = DS.Color.danger
        closedBadge.backgroundColor = DS.Color.background
        closedBadge.isHidden = true

        let topRow = AdaptiveStackView([tile, closedBadge], spacing: DS.Spacing.s, alignment: .top)
        let stack = UIStackView(arrangedSubviews: [topRow, nameLabel, subtitleLabel, metaLabel, reasonLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = DS.Spacing.xs
        stack.setCustomSpacing(DS.Spacing.s, after: topRow)
        stack.setCustomSpacing(DS.Spacing.s, after: metaLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        stack.pin(to: contentView, insets: UIEdgeInsets(
            top: DS.Spacing.m, left: DS.Spacing.m, bottom: DS.Spacing.m, right: DS.Spacing.m
        ))

        isAccessibilityElement = true
        accessibilityTraits = .button
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            if let item = self.item { self.metaLabel.attributedText = item.card.metaText(font: DS.Font.footnote) }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ item: ForYouItem) {
        self.item = item
        let card = item.card
        tile.configure(symbolName: card.symbolName, tint: card.tint)
        tile.alpha = card.isOpen ? 1 : 0.45
        closedBadge.isHidden = card.isOpen
        nameLabel.text = card.name
        subtitleLabel.text = card.subtitle
        subtitleLabel.isHidden = card.subtitle.isEmpty
        metaLabel.attributedText = card.metaText(font: DS.Font.footnote)
        reasonLabel.text = item.reason
        reasonLabel.isHidden = item.reason == nil
        accessibilityLabel = [card.accessibilityDescription, item.reason].compactMap { $0 }.joined(separator: ", ")
    }

    override var isHighlighted: Bool {
        didSet { contentView.backgroundColor = isHighlighted ? DS.Color.separator : DS.Color.surface }
    }
}

/// Horizontal "For you" strip. It sizes itself: its height is the tallest card, so it works as a table header.
final class ForYouCarouselView: UIView, UICollectionViewDelegate {

    var onSelect: ((String) -> Void)?

    private static let regularCardWidth: CGFloat = 270
    private static let verticalInset = DS.Spacing.s

    private var itemsByID: [String: ForYouItem] = [:]
    private var orderedIDs: [String] = []
    private var cardHeight: CGFloat = 140
    private var lastMeasuredWidth: CGFloat = 0
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private var cardWidth: CGFloat {
        guard traitCollection.usesAccessibilityLayout, bounds.width > 0 else { return Self.regularCardWidth }
        return max(Self.regularCardWidth, bounds.width - 2 * DS.Spacing.l)
    }

    private func setUp() {
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        collectionView.pin(to: self)

        let registration = UICollectionView.CellRegistration<ForYouCardCell, String> { [weak self] cell, _, id in
            if let item = self?.itemsByID[id] { cell.configure(item) }
        }
        dataSource = UICollectionViewDiffableDataSource<Int, String>(collectionView: collectionView) { view, indexPath, id in
            view.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: id)
        }
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.remeasure()
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] _, _ in
            let width = self?.cardWidth ?? Self.regularCardWidth
            let height = self?.cardHeight ?? 140
            let size = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .absolute(height))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = DS.Spacing.m
            section.contentInsets = NSDirectionalEdgeInsets(
                top: Self.verticalInset, leading: DS.Spacing.l, bottom: Self.verticalInset, trailing: DS.Spacing.l
            )
            return section
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: cardHeight + 2 * Self.verticalInset)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if traitCollection.usesAccessibilityLayout, bounds.width != lastMeasuredWidth {
            remeasure()
        }
    }

    func setItems(_ items: [ForYouItem]) {
        let previous = itemsByID
        var latest: [String: ForYouItem] = [:]
        var ids: [String] = []
        for item in items where latest[item.card.id] == nil {
            latest[item.card.id] = item
            ids.append(item.card.id)
        }
        itemsByID = latest
        orderedIDs = ids
        remeasure()

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(ids)
        let changed = ids.filter { previous[$0] != nil && previous[$0] != latest[$0] }
        snapshot.reconfigureItems(changed)
        let animate = window != nil && !UIAccessibility.isReduceMotionEnabled
        dataSource?.apply(snapshot, animatingDifferences: animate)
    }

    /// Cards share one height (the tallest at the current text size) so the strip never clips at AX sizes.
    private func remeasure() {
        lastMeasuredWidth = bounds.width
        let probe = ForYouCardCell(frame: .zero)
        probe.traitOverrides.preferredContentSizeCategory = traitCollection.preferredContentSizeCategory
        let width = cardWidth
        var tallest: CGFloat = 0
        for id in orderedIDs {
            guard let item = itemsByID[id] else { continue }
            probe.configure(item)
            let fitted = probe.contentView.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            tallest = max(tallest, fitted.height)
        }
        cardHeight = ceil(max(tallest, 1))
        collectionView.collectionViewLayout.invalidateLayout()
        invalidateIntrinsicContentSize()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if let id = dataSource?.itemIdentifier(for: indexPath) { onSelect?(id) }
    }
}
