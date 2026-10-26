import UIKit

/// A pill that keeps a 44 pt tap area even though it is drawn shorter.
private final class ChipButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extra = max(0, DS.minTapTarget - bounds.height) / 2
        return bounds.insetBy(dx: 0, dy: -extra).contains(point)
    }
}

/// Horizontally scrolling pill chips. Tapping the selected chip clears the selection.
final class ChipBar: UIView {

    var onSelect: ((String?) -> Void)?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var titles: [String] = []
    private var buttons: [ChipButton] = []
    private var selectedTitle: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.pin(to: self)

        stack.axis = .horizontal
        stack.spacing = DS.Spacing.s
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        let content = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: DS.Spacing.s),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -DS.Spacing.s),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: DS.Spacing.l),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -DS.Spacing.l),
            scrollView.frameLayoutGuide.heightAnchor.constraint(equalTo: content.heightAnchor)
        ])
    }

    func setChips(_ titles: [String], selected: String?) {
        let selectionChanged = selected != selectedTitle
        selectedTitle = selected
        if titles != self.titles {
            self.titles = titles
            rebuildButtons()
        }
        updateSelection()
        if selectionChanged, let index = titles.firstIndex(where: { $0 == selected }) {
            layoutIfNeeded()
            scrollView.scrollRectToVisible(buttons[index].frame.insetBy(dx: -DS.Spacing.l, dy: 0), animated: false)
        }
    }

    private func rebuildButtons() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = titles.map { title in
            let button = ChipButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = title
            configuration.cornerStyle = .capsule
            configuration.titleLineBreakMode = .byWordWrapping
            configuration.contentInsets = NSDirectionalEdgeInsets(
                top: DS.Spacing.s, leading: DS.Spacing.l, bottom: DS.Spacing.s, trailing: DS.Spacing.l
            )
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = DS.Font.subheadline
                return attributes
            }
            button.configuration = configuration
            button.configurationUpdateHandler = { button in
                guard var configuration = button.configuration else { return }
                let selected = button.isSelected
                configuration.baseForegroundColor = selected ? DS.Color.chipSelectedText : DS.Color.chipText
                configuration.background.backgroundColor = selected ? DS.Color.chipSelectedBackground : DS.Color.chipBackground
                configuration.background.strokeColor = selected ? DS.Color.chipSelectedBackground : DS.Color.separator
                configuration.background.strokeWidth = 1
                button.configuration = configuration
            }
            button.addAction(UIAction { [weak self] _ in self?.tapped(title) }, for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(button)
            button.widthAnchor.constraint(
                lessThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * DS.Spacing.l
            ).isActive = true
            return button
        }
    }

    private func updateSelection() {
        for (title, button) in zip(titles, buttons) {
            button.isSelected = title == selectedTitle
        }
    }

    private func tapped(_ title: String) {
        selectedTitle = selectedTitle == title ? nil : title
        updateSelection()
        onSelect?(selectedTitle)
    }
}
