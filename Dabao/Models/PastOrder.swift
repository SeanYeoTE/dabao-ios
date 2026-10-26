import Foundation

/// One line of a placed order. A snapshot: receipts never look at the catalogue.
nonisolated struct PastOrderLine: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let menuItemID: String
    let name: String
    let unitPrice: Decimal
    let quantity: Int
    let notes: String

    var subtotal: Decimal {
        unitPrice * Decimal(quantity)
    }
}

/// An order that was placed, frozen at that moment.
nonisolated struct PastOrder: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let placedAt: Date
    let restaurantID: String
    let restaurantName: String
    let cuisine: String
    let imageName: String
    let colorHex: String
    let lines: [PastOrderLine]
    let subtotal: Decimal
    let deliveryFee: Decimal
    let total: Decimal

    var itemCount: Int {
        lines.reduce(0) { $0 + $1.quantity }
    }
}
