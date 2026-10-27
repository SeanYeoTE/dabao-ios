import Foundation

/// One line to put back in the cart when reordering, already clamped to the cart's limits.
nonisolated struct ReorderLine: Equatable, Sendable {
    let item: MenuItem
    let quantity: Int
    let notes: String
}

/// What happens if this order is placed again today.
nonisolated enum ReorderPlan: Equatable, Sendable {
    case ready(restaurant: Restaurant, lines: [ReorderLine])
    case restaurantMissing(name: String)
    case restaurantClosed(name: String)
    case itemsUnavailable(names: [String])
}

/// Checks a past order against today's catalogue. Reorders are all or nothing, so any gap blocks it.
enum ReorderPlanner {

    static func plan(for order: PastOrder, catalog: CatalogStore = .shared) -> ReorderPlan {
        guard let restaurant = catalog.restaurant(id: order.restaurantID) else {
            return .restaurantMissing(name: order.restaurantName)
        }
        guard restaurant.isOpen else {
            return .restaurantClosed(name: restaurant.name)
        }

        var unavailable: [String] = []
        var merged: [(item: MenuItem, quantity: Int, notes: String)] = []
        for line in order.lines {
            guard let item = restaurant.menu.first(where: { $0.id == line.menuItemID }), !item.isSoldOut else {
                if !unavailable.contains(line.name) {
                    unavailable.append(line.name)
                }
                continue
            }
            if let index = merged.firstIndex(where: { $0.item.id == item.id }) {
                merged[index].quantity += line.quantity
                if merged[index].notes.isEmpty {
                    merged[index].notes = line.notes
                }
            } else {
                merged.append((item, line.quantity, line.notes))
            }
        }

        guard unavailable.isEmpty else { return .itemsUnavailable(names: unavailable) }
        let lines = merged.map {
            ReorderLine(item: $0.item,
                        quantity: min(max($0.quantity, 1), CartStore.maxQuantityPerItem),
                        notes: String($0.notes.prefix(CartStore.maxNotesLength)))
        }
        guard !lines.isEmpty else { return .itemsUnavailable(names: order.lines.map(\.name)) }
        return .ready(restaurant: restaurant, lines: lines)
    }
}
