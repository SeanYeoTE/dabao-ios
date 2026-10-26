import UIKit

/// The top of the Menu screen: who the restaurant is, how good it is and how fast it arrives.
final class MenuHeaderView: UIView {

    private let tile = UIView()
    private let symbolView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let infoLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let closedLabel = UILabel()
    private let closedBanner = UIView()
    private let topRow = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        tile.layer.cornerRadius = DS.Radius.card
        tile.translatesAutoresizingMaskIntoConstraints = false
        symbolView.contentMode = .scaleAspectFit
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        symbolView.isAccessibilityElement = false
        tile.addSubview(symbolView)

        configure(titleLabel, font: DS.Font.title2, color: DS.Color.textPrimary)
        configure(subtitleLabel, font: DS.Font.subheadline, color: DS.Color.textSecondary)
        configure(infoLabel, font: DS.Font.subheadline, color: DS.Color.textPrimary)
        configure(descriptionLabel, font: DS.Font.callout, color: DS.Color.textSecondary)

        closedLabel.text = "Closed now. You can browse, but not order."
        closedLabel.font = DS.Font.footnote
        closedLabel.adjustsFontForContentSizeCategory = true
        closedLabel.numberOfLines = 0
        closedLabel.textColor = DS.Color.onBrand
        closedLabel.translatesAutoresizingMaskIntoConstraints = false
        closedBanner.backgroundColor = DS.Color.danger
        closedBanner.layer.cornerRadius = DS.Radius.small
        closedBanner.addSubview(closedLabel)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = DS.Spacing.xs

        topRow.addArrangedSubview(tile)
        topRow.addArrangedSubview(textStack)
        topRow.spacing = DS.Spacing.m
        updateAxis()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: MenuHeaderView, _) in
            self.updateAxis()
        }

        let stack = UIStackView(arrangedSubviews: [topRow, infoLabel, descriptionLabel, closedBanner])
        stack.axis = .vertical
        stack.spacing = DS.Spacing.m
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: DS.Spacing.l),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DS.Spacing.xl),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DS.Spacing.xl),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DS.Spacing.s),

            closedLabel.topAnchor.constraint(equalTo: closedBanner.topAnchor, constant: DS.Spacing.s),
            closedLabel.leadingAnchor.constraint(equalTo: closedBanner.leadingAnchor, constant: DS.Spacing.m),
            closedLabel.trailingAnchor.constraint(equalTo: closedBanner.trailingAnchor, constant: -DS.Spacing.m),
            closedLabel.bottomAnchor.constraint(equalTo: closedBanner.bottomAnchor, constant: -DS.Spacing.s),

            tile.widthAnchor.constraint(equalToConstant: 64),
            tile.heightAnchor.constraint(equalToConstant: 64),
            symbolView.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: tile.centerYAnchor),
            symbolView.widthAnchor.constraint(equalToConstant: 34),
            symbolView.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    /// At the biggest text sizes the tile sits above the name so the name keeps its width.
    private func updateAxis() {
        let isLarge = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        topRow.axis = isLarge ? .vertical : .horizontal
        topRow.alignment = isLarge ? .leading : .center
    }

    private func configure(_ label: UILabel, font: UIFont, color: UIColor) {
        label.font = font
        label.textColor = color
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    func configure(with header: MenuHeaderViewModel) {
        let tint = UIColor(hex: header.colorHex)
        tile.backgroundColor = tint.withAlphaComponent(0.15)
        symbolView.image = UIImage(systemName: header.symbolName)
        symbolView.tintColor = tint

        titleLabel.text = header.title
        subtitleLabel.text = header.subtitle
        infoLabel.text = "★ \(header.ratingText)  ·  \(header.etaText)  ·  \(header.feeText)"
        descriptionLabel.text = header.description
        descriptionLabel.isHidden = header.description.isEmpty
        closedBanner.isHidden = header.isOpen

        titleLabel.accessibilityTraits = .header
        infoLabel.accessibilityLabel = "Rating \(header.ratingText), \(header.etaText), \(header.feeText)"
    }
}
