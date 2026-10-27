import Foundation

/// "Today, 6:42 PM", "Yesterday, 9:05 AM", or "Oct 21, 2026, 7:30 PM" for older orders.
/// Past order cards use the fixed en_GB "25 Oct, 21:27" and deadline "04 Dec 2026" formats instead.
enum OrderDateFormatter {

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let deliveredFormatter = fixed("d MMM, HH:mm")
    private static let deadlineFormatter = fixed("dd MMM yyyy")

    // Two formatters, because the system's own relative date + time format says "Today at 6:42 PM".
    static func string(from date: Date) -> String {
        "\(dayFormatter.string(from: date)), \(timeFormatter.string(from: date))"
    }

    /// "25 Oct, 21:27"
    static func deliveredString(from date: Date) -> String {
        deliveredFormatter.string(from: date)
    }

    /// "04 Dec 2026"
    static func deadlineString(from date: Date) -> String {
        deadlineFormatter.string(from: date)
    }

    private static func fixed(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = format
        return formatter
    }
}
