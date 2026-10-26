import UIKit

/// One dish in the cart: name, a notes button, the line price and a quantity stepper.
final class CartLineCell: UITableViewCell {

    static let reuseIdentifier = "CartLineCell"

    var onQuantityChange: ((Int) -> Void)?
    var onEditNotes: (() -> Void)?

    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let notesButton = UIButton(type: .system)
    private let quantityControl = QuantityControl()
    private let content = UIStackView()
    private let trailingStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: CartLineCell, _) in
            self.updateAxis()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onQuantityChange = nil
        onEditNotes = nil
    }

    private func setUpViews() {
        backgroundColor = DS.Color.surface

        nameLabel.font = DS.Font.headline
        nameLabel.textColor = DS.Color.textPrimary
        priceLabel.font = DS.Font.subheadline
        priceLabel.textColor = DS.Color.textPrimary
        priceLabel.textAlignment = .right
        for label in [nameLabel, priceLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }

        var notesConfig = UIButton.Configuration.plain()
        notesConfig.contentInsets = NSDirectionalEdgeInsets(top: DS.Spacing.s, leading: 0, bottom: DS.Spacing.s, trailing: 0)
        notesConfig.titleLineBreakMode = .byWordWrapping
        notesConfig.titleAlignment = .leading
        notesConfig.background.cornerRadius = DS.Radius.small
        notesButton.configuration = notesConfig
        notesButton.addAction(UIAction { [weak self] _ in self?.onEditNotes?() }, for: .touchUpInside)

        quantityControl.minimumValue = 0
        quantityControl.maximumValue = CartStore.maxQuantityPerItem
        quantityControl.onChange = { [weak self] value in self?.onQuantityChange?(value) }

        let textStack = UIStackView(arrangedSubviews: [nameLabel, notesButton])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = DS.Spacing.xxs

        trailingStack.axis = .vertical
        trailingStack.alignment = .trailing
        trailingStack.spacing = DS.Spacing.xs
        trailingStack.addArrangedSubview(priceLabel)
        trailingStack.addArrangedSubview(quantityControl)

        content.addArrangedSubview(textStack)
        content.addArrangedSubview(trailingStack)
        content.spacing = DS.Spacing.m
        content.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(content)

        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        trailingStack.setContentHuggingPriority(.required, for: .horizontal)
        trailingStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.s),
            content.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DS.Spacing.s),
            notesButton.heightAnchor.constraint(greaterThanOrEqualToConstant: DS.minTapTarget)
        ])
        updateAxis()
    }

    /// At the biggest text sizes the price and stepper move under the name.
    private func updateAxis() {
        let isLarge = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        content.axis = isLarge ? .vertical : .horizontal
        content.alignment = isLarge ? .leading : .top
        trailingStack.alignment = isLarge ? .leading : .trailing
        priceLabel.textAlignment = isLarge ? .natural : .right
    }

    func configure(with line: CartLine) {
        nameLabel.text = line.item.name
        priceLabel.text = PriceFormatter.string(from: line.subtotal)
        quantityControl.maximumValue = CartStore.maxQuantityPerItem
        quantityControl.value = line.quantity

        let hasNotes = !line.notes.isEmpty
        notesButton.configuration?.title = hasNotes ? "Note: \(line.notes)" : "Add a note"
        notesButton.configuration?.baseForegroundColor = hasNotes ? DS.Color.textSecondary : DS.Color.brand
        notesButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = DS.Font.footnote
            return attributes
        }
        notesButton.accessibilityLabel = hasNotes ? "Note: \(line.notes)" : "Add a note"
        notesButton.accessibilityHint = "Edits the note for \(line.item.name)"
        quantityControl.accessibilityLabel = "\(line.item.name) quantity"
    }
}
