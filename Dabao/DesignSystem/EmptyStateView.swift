import UIKit

/// Centred symbol, title, message and an optional action. Scrolls when AX text sizes make it taller than the screen.
final class EmptyStateView: UIView {

    var onAction: (() -> Void)?

    init(symbolName: String, title: String, message: String, actionTitle: String? = nil) {
        super.init(frame: .zero)
        backgroundColor = DS.Color.background

        let imageView = UIImageView()
        let size = UIFontMetrics(forTextStyle: .largeTitle).scaledValue(for: 56)
        imageView.image = UIImage(systemName: symbolName, withConfiguration: UIImage.SymbolConfiguration(pointSize: size, weight: .light))
        imageView.tintColor = DS.Color.brand
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false

        let titleLabel = UILabel.ds(font: DS.Font.title2, color: DS.Color.textPrimary)
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.accessibilityTraits = .header
        let messageLabel = UILabel.ds(font: DS.Font.body, color: DS.Color.textSecondary)
        messageLabel.text = message
        messageLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = DS.Spacing.m
        stack.setCustomSpacing(DS.Spacing.l, after: imageView)

        if let actionTitle {
            let button = PrimaryButton(title: actionTitle)
            button.addAction(UIAction { [weak self] _ in self?.onAction?() }, for: .touchUpInside)
            stack.addArrangedSubview(button)
            stack.setCustomSpacing(DS.Spacing.xl, after: messageLabel)
        }
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(content)
        content.addSubview(stack)
        scrollView.pin(to: self)

        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            content.widthAnchor.constraint(equalTo: frameGuide.widthAnchor),
            content.heightAnchor.constraint(greaterThanOrEqualTo: frameGuide.heightAnchor),

            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            stack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: DS.Spacing.xl),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -DS.Spacing.xl),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: DS.Spacing.xl),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -DS.Spacing.xl)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
