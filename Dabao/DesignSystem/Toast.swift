import UIKit

/// Short bottom pill message. It hides itself after 2 s and announces itself to VoiceOver.
enum Toast {

    private final class ToastView: UIView {}

    static func show(_ message: String, in view: UIView) {
        view.subviews.compactMap { $0 as? ToastView }.forEach { $0.removeFromSuperview() }

        let toast = ToastView()
        toast.backgroundColor = DS.Color.textPrimary
        toast.layer.cornerRadius = DS.Radius.button
        toast.layer.cornerCurve = .continuous
        toast.isUserInteractionEnabled = false
        toast.isAccessibilityElement = false
        toast.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel.ds(font: DS.Font.subheadline, color: DS.Color.surface)
        label.text = message
        label.textAlignment = .center
        toast.addSubview(label)
        label.pin(to: toast, insets: UIEdgeInsets(top: DS.Spacing.m, left: DS.Spacing.l, bottom: DS.Spacing.m, right: DS.Spacing.l))

        view.addSubview(toast)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -(DS.Spacing.xxl + DS.Spacing.xxl)),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor, constant: DS.Spacing.l),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor, constant: -DS.Spacing.l)
        ])

        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        toast.alpha = 0
        toast.transform = reduceMotion ? .identity : CGAffineTransform(translationX: 0, y: DS.Spacing.l)
        UIView.animate(withDuration: reduceMotion ? 0 : 0.25) {
            toast.alpha = 1
            toast.transform = .identity
        }
        UIAccessibility.post(notification: .announcement, argument: message)

        Task { @MainActor [weak toast] in
            try? await Task.sleep(for: .seconds(2))
            guard let toast, toast.superview != nil else { return }
            UIView.animate(withDuration: reduceMotion ? 0 : 0.25, animations: { toast.alpha = 0 }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
