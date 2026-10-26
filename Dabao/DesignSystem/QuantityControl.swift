import UIKit

/// [−] n [+] stepper. VoiceOver sees one adjustable element (swipe up/down), not two small buttons.
final class QuantityControl: UIControl {

    var value: Int = 0 {
        didSet {
            let clamped = min(max(value, minimumValue), maximumValue)
            if clamped != value { value = clamped }
            update()
        }
    }
    var minimumValue: Int = 0 { didSet { value = min(max(value, minimumValue), maximumValue); update() } }
    var maximumValue: Int = 10 { didSet { value = min(max(value, minimumValue), maximumValue); update() } }
    var onChange: ((Int) -> Void)?

    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)
    private let valueLabel = UILabel.ds(font: DS.Font.bodyBold, color: DS.Color.textPrimary, lines: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        configure(minusButton, symbol: "minus.circle", label: "Decrease quantity", delta: -1)
        configure(plusButton, symbol: "plus.circle.fill", label: "Increase quantity", delta: 1)

        valueLabel.textAlignment = .center
        valueLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .bold)
        )
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [minusButton, valueLabel, plusButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = DS.Spacing.xs
        stack.isUserInteractionEnabled = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.pin(to: self)
        valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true

        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        accessibilityLabel = "Quantity"
        update()
    }

    private func configure(_ button: UIButton, symbol: String, label: String, delta: Int) {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .regular))
        configuration.baseForegroundColor = DS.Color.brand
        configuration.contentInsets = .zero
        button.configuration = configuration
        button.accessibilityLabel = label
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: DS.minTapTarget),
            button.heightAnchor.constraint(equalToConstant: DS.minTapTarget)
        ])
        button.addAction(UIAction { [weak self] _ in self?.step(delta) }, for: .touchUpInside)
    }

    private func update() {
        valueLabel.text = "\(value)"
        minusButton.isEnabled = value > minimumValue
        plusButton.isEnabled = value < maximumValue
        accessibilityValue = "\(value)"
    }

    private func step(_ delta: Int) {
        let next = min(max(value + delta, minimumValue), maximumValue)
        guard next != value else { return }
        value = next
        onChange?(next)
        sendActions(for: .valueChanged)
    }

    override func accessibilityIncrement() { step(1) }
    override func accessibilityDecrement() { step(-1) }
}
