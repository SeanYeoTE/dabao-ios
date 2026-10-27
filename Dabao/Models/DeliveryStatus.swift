import Foundation

/// Where an order is on its way to the door.
nonisolated enum DeliveryStage: Int, CaseIterable, Comparable, Sendable {
    case confirmed, preparing, onTheWay, delivered

    var title: String {
        switch self {
        case .confirmed: return "Order confirmed"
        case .preparing: return "Preparing your food"
        case .onTheWay: return "On the way"
        case .delivered: return "Delivered"
        }
    }

    var shortTitle: String {
        switch self {
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .onTheWay: return "On the way"
        case .delivered: return "Delivered"
        }
    }

    static func < (lhs: DeliveryStage, rhs: DeliveryStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A simulated delivery status. Never stored: it's calculated from the clock, so it survives relaunch.
nonisolated struct DeliveryStatus: Equatable, Sendable {
    let orderID: UUID
    let stage: DeliveryStage
    /// 0...1 across the whole delivery.
    let progress: Double
    /// Rounded up, never negative. 0 once delivered.
    let minutesRemaining: Int
    let estimatedArrival: Date

    /// Pure function of time. `minuteLength` is 60 normally, 1 with `-dabaoFastDelivery`.
    /// Orders without `deliveryMinutes` (saved before tracking existed) count as delivered.
    static func make(for order: PastOrder, now: Date, minuteLength: TimeInterval) -> DeliveryStatus {
        guard let minutes = order.deliveryMinutes, minutes > 0, minuteLength > 0 else {
            return DeliveryStatus(orderID: order.id, stage: .delivered, progress: 1, minutesRemaining: 0,
                                  estimatedArrival: order.placedAt)
        }

        let total = Double(minutes) * minuteLength
        let elapsed = now.timeIntervalSince(order.placedAt)
        let progress = min(max(elapsed / total, 0), 1)
        let arrival = order.placedAt.addingTimeInterval(total)

        let stage: DeliveryStage
        switch progress {
        case ..<0.10: stage = .confirmed
        case ..<0.45: stage = .preparing
        case ..<1: stage = .onTheWay
        default: stage = .delivered
        }

        let remaining = stage == .delivered ? 0 : Int(((total - min(max(elapsed, 0), total)) / minuteLength).rounded(.up))
        return DeliveryStatus(orderID: order.id, stage: stage, progress: progress,
                              minutesRemaining: remaining, estimatedArrival: arrival)
    }
}
