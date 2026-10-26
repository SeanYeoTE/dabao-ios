import UIKit

extension UIColor {

    /// "#RRGGBB" (the "#" is optional). Bad input falls back to the brand colour so a typo in data never crashes.
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            self.init { DS.Color.brand.resolvedColor(with: $0) }
            return
        }
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Design tokens. Screens use these instead of literals, so light/dark and Dynamic Type stay consistent.
enum DS {

    enum Color {
        private static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
            UIColor { traits in
                let value = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(
                    red: CGFloat((value >> 16) & 0xFF) / 255,
                    green: CGFloat((value >> 8) & 0xFF) / 255,
                    blue: CGFloat(value & 0xFF) / 255,
                    alpha: 1
                )
            }
        }

        static let brand = dynamic(light: 0xD70F64, dark: 0xFF3D87)
        static let brandPressed = dynamic(light: 0xB00C52, dark: 0xE02A72)
        static let onBrand = UIColor.white

        static let background = dynamic(light: 0xF2F2F4, dark: 0x000000)
        static let surface = dynamic(light: 0xFFFFFF, dark: 0x1C1C1E)
        static let surfaceElevated = dynamic(light: 0xFFFFFF, dark: 0x2C2C2E)

        static let textPrimary = dynamic(light: 0x1F1F24, dark: 0xF5F5F7)
        static let textSecondary = dynamic(light: 0x5F6168, dark: 0xAEAEB4)
        static let textTertiary = dynamic(light: 0x6E7078, dark: 0x8E8E93)
        static let separator = dynamic(light: 0xE4E4E8, dark: 0x3A3A3C)

        static let success = dynamic(light: 0x1E7F4F, dark: 0x4CD28A)
        static let warning = dynamic(light: 0xA55A00, dark: 0xFFB340)
        static let danger = dynamic(light: 0xC62828, dark: 0xFF6B6B)

        static let chipBackground = dynamic(light: 0xFFFFFF, dark: 0x2C2C2E)
        static let chipText = dynamic(light: 0x1F1F24, dark: 0xF5F5F7)
        static let chipSelectedBackground = brand
        static let chipSelectedText = UIColor.white
    }

    /// Every style is scaled with UIFontMetrics, so labels using them need `adjustsFontForContentSizeCategory = true`.
    enum Font {
        private static func scaled(
            _ size: CGFloat, _ weight: UIFont.Weight, _ style: UIFont.TextStyle, rounded: Bool = false
        ) -> UIFont {
            var base = UIFont.systemFont(ofSize: size, weight: weight)
            if rounded, let descriptor = base.fontDescriptor.withDesign(.rounded) {
                base = UIFont(descriptor: descriptor, size: size)
            }
            return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
        }

        static var largeTitle: UIFont { scaled(34, .bold, .largeTitle, rounded: true) }
        static var title: UIFont { scaled(28, .bold, .title1, rounded: true) }
        static var title2: UIFont { scaled(22, .bold, .title2, rounded: true) }
        static var headline: UIFont { scaled(17, .semibold, .headline) }
        static var body: UIFont { scaled(17, .regular, .body) }
        static var bodyBold: UIFont { scaled(17, .bold, .body) }
        static var callout: UIFont { scaled(16, .regular, .callout) }
        static var subheadline: UIFont { scaled(15, .regular, .subheadline) }
        static var footnote: UIFont { scaled(13, .regular, .footnote) }
        static var caption: UIFont { scaled(12, .medium, .caption1) }
    }

    enum Radius {
        static let card: CGFloat = 14
        static let small: CGFloat = 8
        static let button: CGFloat = 24
    }

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    static let minTapTarget: CGFloat = 44

    /// Call once at launch, before any window is created.
    static func applyGlobalAppearance() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithDefaultBackground()
        navigation.titleTextAttributes = [.foregroundColor: Color.textPrimary]
        navigation.largeTitleTextAttributes = [.foregroundColor: Color.textPrimary]
        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithTransparentBackground()
        scrollEdge.titleTextAttributes = navigation.titleTextAttributes
        scrollEdge.largeTitleTextAttributes = navigation.largeTitleTextAttributes
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = navigation
        bar.compactAppearance = navigation
        bar.scrollEdgeAppearance = scrollEdge
        bar.tintColor = Color.brand

        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        for item in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            item.selected.iconColor = Color.brand
            item.selected.titleTextAttributes = [.foregroundColor: Color.brand]
            item.normal.iconColor = Color.textSecondary
            item.normal.titleTextAttributes = [.foregroundColor: Color.textSecondary]
        }
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tab
        tabBar.scrollEdgeAppearance = tab
        tabBar.tintColor = Color.brand

        UISwitch.appearance().onTintColor = Color.brand
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = Color.brand
    }
}
