import UIKit

final class MenuItemCell: UITableViewCell {

    static let reuseIdentifier = "MenuItemCell"

    var onAdd: (() -> Void)?
    var onRemove: (() -> Void)?

    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let priceLabel = UILabel()
    private let soldOutLabel = UILabel()
    private let spicyIcon = UIImageView(image: UIImage(systemName: "flame.fill"))
    private let quantityLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let removeButton = UIButton(type: .system)
    private let buttons = UIStackView()
    private let content = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: MenuItemCell, _) in
            self.updateAxis()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAdd = nil
        onRemove = nil
    }

    private func setUpViews() {
        backgroundColor = DS.Color.surface
        selectionStyle = .none

        style(nameLabel, font: DS.Font.headline, color: DS.Color.textPrimary)
        style(detailLabel, font: DS.Font.footnote, color: DS.Color.textSecondary)
        style(priceLabel, font: DS.Font.subheadline, color: DS.Color.textPrimary)
        style(soldOutLabel, font: DS.Font.caption, color: DS.Color.textTertiary)
        style(quantityLabel, font: DS.Font.bodyBold, color: DS.Color.brand)
        soldOutLabel.text = "Sold out"
        quantityLabel.textAlignment = .center

        spicyIcon.tintColor = DS.Color.danger
        spicyIcon.contentMode = .scaleAspectFit
        spicyIcon.isAccessibilityElement = false

        configureButton(addButton, symbol: "plus.circle.fill")
        configureButton(removeButton, symbol: "minus.circle")
        addButton.addAction(UIAction { [weak self] _ in self?.onAdd?() }, for: .touchUpInside)
        removeButton.addAction(UIAction { [weak self] _ in self?.onRemove?() }, for: .touchUpInside)

        let nameRow = UIStackView(arrangedSubviews: [nameLabel, spicyIcon])
        nameRow.spacing = DS.Spacing.xs
        nameRow.alignment = .firstBaseline

        let priceRow = UIStackView(arrangedSubviews: [priceLabel, soldOutLabel])
        priceRow.spacing = DS.Spacing.s
        priceRow.alignment = .firstBaseline

        let textStack = UIStackView(arrangedSubviews: [nameRow, detailLabel, priceRow])
        textStack.axis = .vertical
        textStack.spacing = DS.Spacing.xs
        textStack.alignment = .leading

        buttons.addArrangedSubview(removeButton)
        buttons.addArrangedSubview(quantityLabel)
        buttons.addArrangedSubview(addButton)
        buttons.alignment = .center

        content.addArrangedSubview(textStack)
        content.addArrangedSubview(buttons)
        content.spacing = DS.Spacing.m
        content.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(content)

        // Spare space goes to the text, not to the buttons.
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        buttons.setContentHuggingPriority(.required, for: .horizontal)
        buttons.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.s),
            content.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            content.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DS.Spacing.s),
            content.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            spicyIcon.widthAnchor.constraint(equalToConstant: 14),
            spicyIcon.heightAnchor.constraint(equalToConstant: 14),
            quantityLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: DS.Spacing.xl + DS.Spacing.s),
            addButton.widthAnchor.constraint(equalToConstant: DS.minTapTarget),
            addButton.heightAnchor.constraint(equalToConstant: DS.minTapTarget),
            removeButton.widthAnchor.constraint(equalToConstant: DS.minTapTarget),
            removeButton.heightAnchor.constraint(equalToConstant: DS.minTapTarget)
        ])
        updateAxis()
    }

    private func style(_ label: UILabel, font: UIFont, color: UIColor) {
        label.font = font
        label.textColor = color
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private func configureButton(_ button: UIButton, symbol: String) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: symbol)
        config.baseForegroundColor = DS.Color.brand
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 26)
        button.configuration = config
    }

    /// At the biggest text sizes the buttons move under the text so the text keeps its width.
    private func updateAxis() {
        let isLarge = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        content.axis = isLarge ? .vertical : .horizontal
        content.alignment = isLarge ? .leading : .center
    }

    func configure(with row: MenuItemViewModel) {
        nameLabel.text = row.name
        detailLabel.text = row.detail
        detailLabel.isHidden = row.detail.isEmpty
        priceLabel.text = row.priceText
        spicyIcon.isHidden = !row.isSpicy
        soldOutLabel.isHidden = !row.isSoldOut
        quantityLabel.text = row.quantityText
        quantityLabel.isHidden = row.quantityText == nil
        removeButton.isHidden = row.quantityText == nil

        // Sold-out dishes are greyed out.
        nameLabel.alpha = row.isSoldOut ? 0.5 : 1
        detailLabel.alpha = row.isSoldOut ? 0.5 : 1
        priceLabel.alpha = row.isSoldOut ? 0.5 : 1
        addButton.isEnabled = !row.isSoldOut

        addButton.accessibilityLabel = "Add \(row.name)"
        removeButton.accessibilityLabel = "Remove one \(row.name)"
        quantityLabel.accessibilityLabel = row.quantityText.map { "\($0.replacingOccurrences(of: "×", with: "")) in cart" }
        nameLabel.accessibilityLabel = row.isSpicy ? "\(row.name), spicy" : row.name
    }
}
