import Foundation

/// One dish on a restaurant's menu.
nonisolated struct MenuItem: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let price: Decimal
    let category: String
    let isSoldOut: Bool
    let isSpicy: Bool
    let tags: [String]

    init(id: String, name: String, description: String, price: Decimal, category: String,
         isSoldOut: Bool, isSpicy: Bool, tags: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.category = category
        self.isSoldOut = isSoldOut
        self.isSpicy = isSpicy
        self.tags = tags
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, price, category, isSoldOut, isSpicy, tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        // Decode as Double and round, so 4.5 never turns into 4.5000000000000002.
        price = Decimal(money: try container.decode(Double.self, forKey: .price))
        category = try container.decode(String.self, forKey: .category)
        isSoldOut = try container.decode(Bool.self, forKey: .isSoldOut)
        isSpicy = try container.decode(Bool.self, forKey: .isSpicy)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

nonisolated extension Decimal {
    /// A money amount from a Double, rounded to 2 decimal places via its string form (no binary drift).
    init(money value: Double) {
        self = Decimal(string: String(format: "%.2f", value)) ?? 0
    }
}
