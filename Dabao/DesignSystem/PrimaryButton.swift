import UIKit

/// Brand filled pill button, at least 50 pt tall. The title wraps at large text sizes.
final class PrimaryButton: UIButton {

    init(title: String) {
        super.init(frame: .zero)
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .capsule
        configuration.titleLineBreakMode = .byWordWrapping
        configuration.titleAlignment = .center
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: DS.Spacing.m + DS.Spacing.xs, leading: DS.Spacing.xl, bottom: DS.Spacing.m + DS.Spacing.xs, trailing: DS.Spacing.xl
        )
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = DS.Font.headline
            return attributes
        }
        self.configuration = configuration
        configurationUpdateHandler = { button in
            guard var configuration = button.configuration else { return }
            if !button.isEnabled {
                configuration.baseBackgroundColor = DS.Color.separator
                configuration.baseForegroundColor = DS.Color.textTertiary
            } else {
                configuration.baseBackgroundColor = button.isHighlighted ? DS.Color.brandPressed : DS.Color.brand
                configuration.baseForegroundColor = DS.Color.onBrand
            }
            button.configuration = configuration
        }
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
