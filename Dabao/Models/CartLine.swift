import Foundation

/// A line in the cart: which dish, how many, and any note for the kitchen.
nonisolated struct CartLine: Hashable, Identifiable, Sendable {
    let id: UUID
    let item: MenuItem
    var quantity: Int
    var notes: String

    var subtotal: Decimal {
        item.price * Decimal(quantity)
    }

    init(id: UUID = UUID(), item: MenuItem, quantity: Int, notes: String = "") {
        self.id = id
        self.item = item
        self.quantity = quantity
        self.notes = notes
    }
}
