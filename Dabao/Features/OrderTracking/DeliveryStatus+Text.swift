import Foundation

extension DeliveryStatus {

    /// "On the way · 12 min", used by the floating bar and the Orders tab.
    var summaryText: String {
        "\(stage.shortTitle) · \(minutesRemaining) min"
    }
}
