import UIKit

/// Five stars in the brand colour. Editable stars are one adjustable VoiceOver element, so swiping up or down rates.
final class StarRatingView: UIView {

    static let maxRating = 5

    /// 1...5. Only called while editable, and never for the rating already shown.
    var onSelect: ((Int) -> Void)?

    private let stack = UIStackView()
    private var buttons: [UIButton] = []
    private(set) var rating: Int?
    private var isEditable = false
    private var deadlineText: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.pin(to: self)

        for value in 1...StarRatingView.maxRating {
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = .zero
            configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
            let button = UIButton(configuration: configuration)
            button.tag = value
            button.tintColor = DS.Color.brand
            button.isAccessibilityElement = false
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addAction(UIAction { [weak self] _ in self?.select(value) }, for: .touchUpInside)
            stack.addArrangedSubview(button)
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(greaterThanOrEqualToConstant: DS.minTapTarget),
                button.heightAnchor.constraint(greaterThanOrEqualToConstant: DS.minTapTarget)
            ])
            buttons.append(button)
        }

        isAccessibilityElement = true
        accessibilityLabel = "Rating"
        apply()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// `deadlineText` ("30 Oct 2026") feeds the VoiceOver hint while editable.
    func configure(rating: Int?, isEditable: Bool, deadlineText: String?) {
        self.rating = rating.map { min(max($0, 1), StarRatingView.maxRating) }
        self.isEditable = isEditable
        self.deadlineText = deadlineText
        apply()
    }

    private func select(_ value: Int) {
        guard isEditable, value != rating else { return }
        rating = value
        apply()
        onSelect?(value)
    }

    private func apply() {
        let filled = rating ?? 0
        for button in buttons {
            button.configuration?.image = UIImage(systemName: button.tag <= filled ? "star.fill" : "star")
            button.isUserInteractionEnabled = isEditable
        }
        accessibilityValue = rating.map { "\($0) of \(StarRatingView.maxRating) stars" } ?? "Not rated"
        accessibilityTraits = isEditable ? .adjustable : .staticText
        if isEditable, let deadlineText, !deadlineText.isEmpty {
            accessibilityHint = "Rate by \(deadlineText)"
        } else {
            accessibilityHint = nil
        }
    }

    override func accessibilityIncrement() {
        select(min((rating ?? 0) + 1, StarRatingView.maxRating))
    }

    override func accessibilityDecrement() {
        select(max((rating ?? 1) - 1, 1))
    }
}
