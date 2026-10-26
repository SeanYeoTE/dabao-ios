import UIKit

/// Brand screen shown while the catalogue loads. It lasts about 0.8 s, and not at all when Reduce Motion is on.
final class SplashViewController: UIViewController {

    private static let duration: Duration = .milliseconds(800)

    private let onFinish: () -> Void
    private let contentStack = UIStackView()
    private var hasFinished = false
    private var finishTask: Task<Void, Never>?

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.Color.brand

        let symbolSize = UIFontMetrics(forTextStyle: .largeTitle).scaledValue(for: 72)
        let imageView = UIImageView(image: UIImage(
            systemName: "bag.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .semibold)
        ))
        imageView.tintColor = DS.Color.onBrand
        imageView.contentMode = .scaleAspectFit

        let wordmark = UILabel()
        wordmark.text = "dabao"
        wordmark.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
            for: UIFont.systemFont(ofSize: 44, weight: .heavy).withRoundedDesign()
        )
        wordmark.adjustsFontForContentSizeCategory = true
        wordmark.textColor = DS.Color.onBrand
        wordmark.numberOfLines = 0
        wordmark.textAlignment = .center

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = DS.Spacing.m
        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(wordmark)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.isAccessibilityElement = true
        contentStack.accessibilityLabel = "dabao"
        contentStack.accessibilityTraits = .image
        view.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard finishTask == nil else { return }

        if UIAccessibility.isReduceMotionEnabled {
            finish()
            return
        }

        contentStack.alpha = 0
        contentStack.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
            self.contentStack.alpha = 1
            self.contentStack.transform = .identity
        }
        finishTask = Task { [weak self] in
            try? await Task.sleep(for: Self.duration)
            guard !Task.isCancelled else { return }
            self?.finish()
        }
    }

    private func finish() {
        guard !hasFinished else { return }
        hasFinished = true
        onFinish()
    }
}

private extension UIFont {
    func withRoundedDesign() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
