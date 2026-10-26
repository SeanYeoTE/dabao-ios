import Foundation

/// "Today, 6:42 PM", "Yesterday, 9:05 AM", or "Oct 21, 2026, 7:30 PM" for older orders.
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

    // Two formatters, because the system's own relative date + time format says "Today at 6:42 PM".
    static func string(from date: Date) -> String {
        "\(dayFormatter.string(from: date)), \(timeFormatter.string(from: date))"
    }
}
