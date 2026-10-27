import UIKit

extension DS {

    /// Avatar colours. Every one keeps white initials at 4.5:1 or better in light and dark mode,
    /// so pink here is darker than `DS.Color.brand` in dark mode.
    enum AvatarPalette {
        static let names = ["pink", "orange", "green", "blue", "purple", "teal"]

        private static let hex: [String: (light: UInt32, dark: UInt32)] = [
            "pink": (0xD70F64, 0xC2185B),
            "orange": (0xB34700, 0xA84300),
            "green": (0x1E7F4F, 0x1B7347),
            "blue": (0x1F5FBF, 0x2A62C9),
            "purple": (0x7B3FBF, 0x7E47C9),
            "teal": (0x00786F, 0x007A70),
        ]

        /// Unknown names fall back to pink, the brand colour.
        static func color(named name: String) -> UIColor {
            let pair = hex[name] ?? hex["pink"] ?? (0xD70F64, 0xC2185B)
            return UIColor { traits in
                let value = traits.userInterfaceStyle == .dark ? pair.dark : pair.light
                return UIColor(red: CGFloat((value >> 16) & 0xFF) / 255,
                               green: CGFloat((value >> 8) & 0xFF) / 255,
                               blue: CGFloat(value & 0xFF) / 255,
                               alpha: 1)
            }
        }
    }
}

/// A round avatar showing initials, an emoji or an SF Symbol. It stays the same size at every text size,
/// and is hidden from VoiceOver because the view around it says who it is.
final class AvatarView: UIView {

    enum Size {
        case small, large

        var points: CGFloat { self == .small ? 44 : 88 }
    }

    enum Content: Equatable {
        case initials(String)
        case emoji(String)
        case symbol(String)
    }

    private let size: Size
    private let label = UILabel()
    private let imageView = UIImageView()

    init(size: Size) {
        self.size = size
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = size.points / 2
        layer.cornerCurve = .circular
        clipsToBounds = true
        isAccessibilityElement = false

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        addSubview(label)
        addSubview(imageView)

        let inset = size.points * 0.18
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.points),
            heightAnchor.constraint(equalToConstant: size.points),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: inset / 2),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -inset / 2),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(content: Content, tint: UIColor) {
        switch content {
        case .initials(let text):
            backgroundColor = tint
            label.isHidden = false
            imageView.isHidden = true
            label.text = text
            label.textColor = .white
            label.font = Self.roundedBold(size: size.points * 0.38)
        case .emoji(let emoji):
            // A pale tint behind the emoji, so it reads on its own colours.
            backgroundColor = tint.withAlphaComponent(0.2)
            label.isHidden = false
            imageView.isHidden = true
            label.text = emoji
            label.font = .systemFont(ofSize: size.points * 0.5)
        case .symbol(let name):
            backgroundColor = tint
            label.isHidden = true
            imageView.isHidden = false
            imageView.image = UIImage(systemName: name)
        }
    }

    private static func roundedBold(size: CGFloat) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: .bold)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
