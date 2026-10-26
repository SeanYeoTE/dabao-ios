import Foundation

/// A restaurant on Dabao. Loaded from `restaurants.json`.
nonisolated struct Restaurant: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let cuisine: String
    let rating: Double
    let deliveryMinutes: Int
    let deliveryFee: Decimal
    let isOpen: Bool
    /// An SF Symbol name.
    let imageName: String
    let menu: [MenuItem]
    let tags: [String]
    let description: String
    let area: String
    let reviewCount: Int
    /// 1...4, shown as $ to $$$$.
    let priceLevel: Int
    /// "#RRGGBB"
    let colorHex: String

    init(id: String, name: String, cuisine: String, rating: Double, deliveryMinutes: Int,
         deliveryFee: Decimal, isOpen: Bool, imageName: String, menu: [MenuItem],
         tags: [String] = [], description: String = "", area: String = "",
         reviewCount: Int = 0, priceLevel: Int = 1, colorHex: String = "#D70F64") {
        self.id = id
        self.name = name
        self.cuisine = cuisine
        self.rating = rating
        self.deliveryMinutes = deliveryMinutes
        self.deliveryFee = deliveryFee
        self.isOpen = isOpen
        self.imageName = imageName
        self.menu = menu
        self.tags = tags
        self.description = description
        self.area = area
        self.reviewCount = reviewCount
        self.priceLevel = priceLevel
        self.colorHex = colorHex
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, cuisine, rating, deliveryMinutes, deliveryFee, isOpen, imageName, menu
        case tags, description, area, reviewCount, priceLevel, colorHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        cuisine = try container.decode(String.self, forKey: .cuisine)
        rating = try container.decode(Double.self, forKey: .rating)
        deliveryMinutes = try container.decode(Int.self, forKey: .deliveryMinutes)
        deliveryFee = Decimal(money: try container.decode(Double.self, forKey: .deliveryFee))
        isOpen = try container.decode(Bool.self, forKey: .isOpen)
        imageName = try container.decode(String.self, forKey: .imageName)
        menu = try container.decode([MenuItem].self, forKey: .menu)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        area = try container.decodeIfPresent(String.self, forKey: .area) ?? ""
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
        priceLevel = try container.decodeIfPresent(Int.self, forKey: .priceLevel) ?? 1
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "#D70F64"
    }
}
