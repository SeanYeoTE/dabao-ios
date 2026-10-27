import UIKit

/// Plain values for `OrderStatusBar`. The title reads "On the way · 12 min" or "Delivered".
struct OrderStatusBarModel: Hashable {
    let symbolName: String
    let tint: UIColor
    let title: String
    let subtitle: String
    let progress: Double
    let extraCount: Int
    let isDelivered: Bool
}

/// Floating pill showing the active order: symbol tile, stage and ETA, restaurant, a progress line and a chevron.
/// The caller owns placement and hides it when no order is active.
final class OrderStatusBar: UIControl {

    var onTap: (() -> Void)?

    private let clipView = UIView()
    private let tile = SymbolTileView(side: 40)
    private let titleLabel = UILabel.ds(font: DS.Font.headline, color: DS.Color.textPrimary)
    private let subtitleLabel = UILabel.ds(font: DS.Font.subheadline, color: DS.Color.textSecondary)
    private let badgeLabel = InsetLabel()
    private let chevron = UIImageView()
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private var content: AdaptiveStackView?
    private var model: OrderStatusBarModel?
    private var displayedProgress: Double = 0

    private static let progressHeight: CGFloat = 3

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            let apply = { self.clipView.backgroundColor = self.isHighlighted ? DS.Color.separator : DS.Color.surfaceElevated }
            if UIAccessibility.isReduceMotionEnabled {
                apply()
            } else {
                UIView.animate(withDuration: 0.12, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: apply)
            }
        }
    }

    private func setUp() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = DS.Radius.card
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 3)

        clipView.backgroundColor = DS.Color.surfaceElevated
        clipView.layer.cornerRadius = DS.Radius.card
        clipView.layer.cornerCurve = .continuous
        clipView.layer.masksToBounds = true
        clipView.layer.borderWidth = 0.5
        clipView.isUserInteractionEnabled = false
        clipView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(clipView)
        clipView.pin(to: self)

        let texts = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        texts.axis = .vertical
        texts.spacing = DS.Spacing.xxs
        texts.translatesAutoresizingMaskIntoConstraints = false
        texts.setContentHuggingPriority(.defaultLow, for: .horizontal)

        badgeLabel.font = DS.Font.caption
        badgeLabel.adjustsFontForContentSizeCategory = true
        badgeLabel.textColor = DS.Color.brand
        badgeLabel.backgroundColor = DS.Color.brand.withAlphaComponent(0.14)
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.setContentHuggingPriority(.required, for: .horizontal)
        badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        badgeLabel.isAccessibilityElement = false

        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        chevron.tintColor = DS.Color.textTertiary
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.setContentCompressionResistancePriority(.required, for: .horizontal)
        chevron.translatesAutoresizingMaskIntoConstraints = false

        let root = AdaptiveStackView([tile, texts, badgeLabel, chevron])
        root.isUserInteractionEnabled = false
        content = root
        clipView.addSubview(root)
        root.pin(to: clipView, insets: UIEdgeInsets(top: DS.Spacing.m, left: DS.Spacing.m, bottom: DS.Spacing.m, right: DS.Spacing.l))

        progressTrack.backgroundColor = DS.Color.separator
        progressTrack.isUserInteractionEnabled = false
        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        progressFill.backgroundColor = DS.Color.brand
        progressTrack.addSubview(progressFill)
        clipView.addSubview(progressTrack)
        NSLayoutConstraint.activate([
            progressTrack.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            progressTrack.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            progressTrack.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),
            progressTrack.heightAnchor.constraint(equalToConstant: Self.progressHeight),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])

        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityHint = "Shows order tracking"

        updateBorderColor()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.updateAdaptiveParts()
        }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateBorderColor()
            self.layer.shadowOpacity = self.traitCollection.userInterfaceStyle == .dark ? 0.5 : 0.18
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: DS.Radius.card).cgPath
        layoutProgressFill()
    }

    func configure(_ model: OrderStatusBarModel, animated: Bool) {
        let previous = self.model
        self.model = model
        let shouldAnimate = animated && window != nil && !UIAccessibility.isReduceMotionEnabled

        let apply = {
            self.titleLabel.text = model.title
            let symbol = model.isDelivered ? "checkmark" : model.symbolName
            self.tile.configure(symbolName: symbol, tint: model.isDelivered ? DS.Color.success : model.tint)
            self.progressFill.backgroundColor = model.isDelivered ? DS.Color.success : DS.Color.brand
            self.chevron.isHidden = model.isDelivered || self.traitCollection.usesAccessibilityLayout
            self.updateAdaptiveParts()
        }

        if shouldAnimate, let previous, previous.isDelivered != model.isDelivered || previous.title != model.title || previous.subtitle != model.subtitle {
            UIView.transition(with: clipView, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction], animations: apply)
        } else {
            apply()
        }

        let progress = min(max(model.progress, 0), 1)
        let target = model.isDelivered ? 1 : progress
        if shouldAnimate {
            displayedProgress = target
            UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]) {
                self.layoutProgressFill()
            }
        } else {
            displayedProgress = target
            layoutProgressFill()
        }

        updateAccessibility(model)
    }

    private func layoutProgressFill() {
        let width = progressTrack.bounds.width * displayedProgress
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let x = isRTL ? progressTrack.bounds.width - width : 0
        progressFill.frame = CGRect(x: x, y: 0, width: width, height: Self.progressHeight)
    }

    /// At accessibility sizes the tile and chevron are dropped and "+N" joins the subtitle, so text gets the full width.
    private func updateAdaptiveParts() {
        guard let model else { return }
        let compact = traitCollection.usesAccessibilityLayout
        tile.isHidden = compact
        chevron.isHidden = compact || model.isDelivered
        badgeLabel.isHidden = compact || model.extraCount <= 0
        badgeLabel.text = "+\(model.extraCount)"
        subtitleLabel.text = compact && model.extraCount > 0 ? "\(model.subtitle) · +\(model.extraCount)" : model.subtitle
    }

    private func updateBorderColor() {
        clipView.layer.borderColor = DS.Color.separator.resolvedColor(with: traitCollection).cgColor
    }

    private func updateAccessibility(_ model: OrderStatusBarModel) {
        var parts = ["Order from \(model.subtitle)"]
        if model.isDelivered {
            parts.append("delivered")
        } else {
            let pieces = model.title.components(separatedBy: " · ")
            parts.append((pieces.first ?? model.title).lowercased())
            if pieces.count > 1 { parts.append("about " + Self.spokenDuration(pieces[1])) }
        }
        if model.extraCount > 0 {
            parts.append("\(model.extraCount) more \(model.extraCount == 1 ? "order" : "orders")")
        }
        accessibilityLabel = parts.joined(separator: ", ")
    }

    /// "12 min" -> "12 minutes", "1 min" -> "1 minute". Anything else is read as is.
    private static func spokenDuration(_ text: String) -> String {
        let words = text.split(separator: " ")
        guard words.count == 2, words[1] == "min", let value = Int(words[0]) else { return text }
        return "\(value) \(value == 1 ? "minute" : "minutes")"
    }
}
