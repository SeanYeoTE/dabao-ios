import UIKit

/// Vertical stepper (Confirmed → Preparing → On the way → Delivered).
/// Done steps are a filled brand dot with a check, the current step a pulsing ring, future steps grey.
final class DeliveryTimelineView: UIView {

    private enum StepState {
        case done, current, future

        var spokenSuffix: String {
            switch self {
            case .done: "completed"
            case .current: "current step"
            case .future: "upcoming"
            }
        }
    }

    private final class StepRow: UIView {

        private static let dotSize: CGFloat = 24

        private let dot = UIView()
        private let checkView = UIImageView()
        private let innerDot = UIView()
        private let pulse = UIView()
        private let connector = UIView()
        private let label = UILabel.ds(font: DS.Font.body, color: DS.Color.textPrimary)
        private let showsConnector: Bool
        private(set) var state: StepState = .future
        private var connectorDone = false

        init(title: String, showsConnector: Bool) {
            self.showsConnector = showsConnector
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            label.text = title

            pulse.layer.cornerRadius = Self.dotSize / 2
            pulse.backgroundColor = DS.Color.brand.withAlphaComponent(0.3)
            pulse.isHidden = true
            pulse.translatesAutoresizingMaskIntoConstraints = false

            dot.layer.cornerRadius = Self.dotSize / 2
            dot.layer.borderWidth = 2
            dot.translatesAutoresizingMaskIntoConstraints = false

            checkView.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))
            checkView.tintColor = DS.Color.onBrand
            checkView.contentMode = .center
            checkView.translatesAutoresizingMaskIntoConstraints = false

            innerDot.backgroundColor = DS.Color.brand
            innerDot.layer.cornerRadius = 5
            innerDot.translatesAutoresizingMaskIntoConstraints = false

            connector.translatesAutoresizingMaskIntoConstraints = false
            connector.isHidden = !showsConnector

            addSubview(connector)
            addSubview(pulse)
            addSubview(dot)
            dot.addSubview(checkView)
            dot.addSubview(innerDot)
            addSubview(label)

            let rowHeight = heightAnchor.constraint(greaterThanOrEqualToConstant: DS.minTapTarget + DS.Spacing.s)
            rowHeight.priority = .defaultHigh
            NSLayoutConstraint.activate([
                dot.leadingAnchor.constraint(equalTo: leadingAnchor),
                dot.topAnchor.constraint(equalTo: topAnchor, constant: DS.Spacing.xxs),
                dot.widthAnchor.constraint(equalToConstant: Self.dotSize),
                dot.heightAnchor.constraint(equalToConstant: Self.dotSize),
                pulse.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
                pulse.centerYAnchor.constraint(equalTo: dot.centerYAnchor),
                pulse.widthAnchor.constraint(equalTo: dot.widthAnchor),
                pulse.heightAnchor.constraint(equalTo: dot.heightAnchor),
                checkView.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
                checkView.centerYAnchor.constraint(equalTo: dot.centerYAnchor),
                innerDot.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
                innerDot.centerYAnchor.constraint(equalTo: dot.centerYAnchor),
                innerDot.widthAnchor.constraint(equalToConstant: 10),
                innerDot.heightAnchor.constraint(equalToConstant: 10),
                connector.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
                connector.widthAnchor.constraint(equalToConstant: 2),
                connector.topAnchor.constraint(equalTo: dot.bottomAnchor, constant: DS.Spacing.xs),
                connector.bottomAnchor.constraint(equalTo: bottomAnchor),
                label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: DS.Spacing.m),
                label.trailingAnchor.constraint(equalTo: trailingAnchor),
                label.topAnchor.constraint(equalTo: topAnchor),
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DS.Spacing.l),
                rowHeight
            ])

            isAccessibilityElement = true
            apply(.future, connectorDone: false)
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.apply(self.state, connectorDone: self.connectorDone)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func apply(_ newState: StepState, connectorDone: Bool) {
            state = newState
            self.connectorDone = connectorDone
            label.font = newState == .current ? DS.Font.bodyBold : DS.Font.body
            label.textColor = newState == .future ? DS.Color.textSecondary : DS.Color.textPrimary
            checkView.isHidden = newState != .done
            innerDot.isHidden = newState != .current
            pulse.isHidden = newState != .current
            switch newState {
            case .done:
                dot.backgroundColor = DS.Color.brand
                dot.layer.borderColor = DS.Color.brand.resolvedColor(with: traitCollection).cgColor
            case .current:
                dot.backgroundColor = DS.Color.surface
                dot.layer.borderColor = DS.Color.brand.resolvedColor(with: traitCollection).cgColor
            case .future:
                dot.backgroundColor = DS.Color.surface
                dot.layer.borderColor = DS.Color.textTertiary.resolvedColor(with: traitCollection).cgColor
            }
            connector.backgroundColor = connectorDone ? DS.Color.brand : DS.Color.separator
            accessibilityLabel = "\(label.text ?? ""), \(newState.spokenSuffix)"
            updatePulse()
        }

        func updatePulse() {
            pulse.layer.removeAllAnimations()
            guard state == .current, window != nil, !UIAccessibility.isReduceMotionEnabled else {
                pulse.transform = .identity
                pulse.alpha = state == .current ? 1 : 0
                return
            }
            pulse.alpha = 1
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 1.0
            scale.toValue = 1.7
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.0
            let group = CAAnimationGroup()
            group.animations = [scale, fade]
            group.duration = 1.4
            group.repeatCount = .infinity
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            pulse.layer.add(group, forKey: "pulse")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            updatePulse()
        }
    }

    private let stack = UIStackView()
    private var rows: [StepRow] = []
    private var stages: [String] = []
    private var currentIndex = 0
    private nonisolated(unsafe) var observers: [NSObjectProtocol] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    private func setUp() {
        translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.pin(to: self)
        shouldGroupAccessibilityChildren = true

        // Animations are dropped when the app goes to the background, so the pulse restarts on return.
        let restart: @Sendable (Notification) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.rows.forEach { $0.updatePulse() } }
        }
        observers = [
            NotificationCenter.default.addObserver(
                forName: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil, queue: .main, using: restart
            ),
            NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: restart
            )
        ]
    }

    func configure(stages: [String], currentIndex: Int, animated: Bool) {
        let clamped = stages.isEmpty ? 0 : min(max(currentIndex, 0), stages.count - 1)
        let rebuild = stages != self.stages
        self.stages = stages
        self.currentIndex = clamped

        if rebuild {
            rows.forEach { $0.removeFromSuperview() }
            rows = stages.enumerated().map { StepRow(title: $1, showsConnector: $0 < stages.count - 1) }
            rows.forEach(stack.addArrangedSubview)
            accessibilityElements = rows
        }

        let shouldAnimate = animated && !rebuild && window != nil && !UIAccessibility.isReduceMotionEnabled
        for (index, row) in rows.enumerated() {
            let state: StepState = index < clamped ? .done : (index == clamped ? .current : .future)
            guard row.state != state || rebuild else { continue }
            let apply = { row.apply(state, connectorDone: index < clamped) }
            if shouldAnimate {
                UIView.transition(with: row, duration: 0.3, options: [.transitionCrossDissolve, .allowUserInteraction], animations: apply)
            } else {
                apply()
            }
        }
    }
}
