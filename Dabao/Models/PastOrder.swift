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
    /// The restaurant's delivery estimate when the order was placed. Nil for orders saved before tracking existed.
    let deliveryMinutes: Int?
    /// The restaurant's neighbourhood when the order was placed, used to place it on the delivery map. Nil for older orders.
    let restaurantArea: String?

    init(id: UUID, placedAt: Date, restaurantID: String, restaurantName: String, cuisine: String,
         imageName: String, colorHex: String, lines: [PastOrderLine], subtotal: Decimal,
         deliveryFee: Decimal, total: Decimal, deliveryMinutes: Int? = nil,
         restaurantArea: String? = nil) {
        self.id = id
        self.placedAt = placedAt
        self.restaurantID = restaurantID
        self.restaurantName = restaurantName
        self.cuisine = cuisine
        self.imageName = imageName
        self.colorHex = colorHex
        self.lines = lines
        self.subtotal = subtotal
        self.deliveryFee = deliveryFee
        self.total = total
        self.deliveryMinutes = deliveryMinutes
        self.restaurantArea = restaurantArea
    }

    var itemCount: Int {
        lines.reduce(0) { $0 + $1.quantity }
    }
}
