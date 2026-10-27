import UIKit

/// A labelled text field with an error line underneath. The error is announced to VoiceOver when it appears.
final class FormFieldView: UIView {

    let textField = UITextField()
    var onTextChange: ((String) -> Void)?

    var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    private let titleLabel = UILabel.ds(font: DS.Font.footnote, color: DS.Color.textSecondary)
    private let errorLabel = UILabel.ds(font: DS.Font.footnote, color: DS.Color.danger)
    private let fieldLabel: String

    init(label: String, placeholder: String,
         keyboardType: UIKeyboardType = .default,
         textContentType: UITextContentType? = nil,
         autocapitalization: UITextAutocapitalizationType = .sentences) {
        fieldLabel = label
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = label
        titleLabel.isAccessibilityElement = false

        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.textContentType = textContentType
        textField.autocapitalizationType = autocapitalization
        textField.autocorrectionType = .no
        textField.font = DS.Font.body
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = DS.Color.textPrimary
        textField.backgroundColor = DS.Color.surface
        textField.layer.cornerRadius = DS.Radius.small
        textField.layer.cornerCurve = .continuous
        textField.layer.borderWidth = 1
        textField.layer.borderColor = DS.Color.separator.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: DS.Spacing.m, height: 1))
        textField.leftViewMode = .always
        textField.clearButtonMode = .whileEditing
        textField.accessibilityLabel = label
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onTextChange?(self.text)
        }, for: .editingChanged)

        errorLabel.isHidden = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, textField, errorLabel])
        stack.axis = .vertical
        stack.spacing = DS.Spacing.xs
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.pin(to: self)
        textField.heightAnchor.constraint(greaterThanOrEqualToConstant: DS.minTapTarget).isActive = true

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateBorder()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// nil hides the error.
    func setError(_ message: String?) {
        let wasHidden = errorLabel.isHidden
        errorLabel.text = message
        errorLabel.isHidden = message == nil
        textField.accessibilityValue = message.map { "\(text), \($0)" }
        updateBorder()
        if let message, wasHidden {
            UIAccessibility.post(notification: .announcement, argument: "\(fieldLabel): \(message)")
        }
    }

    private func updateBorder() {
        let color = errorLabel.isHidden ? DS.Color.separator : DS.Color.danger
        textField.layer.borderColor = color.resolvedColor(with: traitCollection).cgColor
    }
}
