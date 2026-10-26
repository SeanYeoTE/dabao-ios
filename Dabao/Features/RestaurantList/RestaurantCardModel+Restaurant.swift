import UIKit

extension RestaurantCardModel {

    /// Turns a restaurant into exactly what a card shows. Shared by the Home list and the "For you" carousel.
    init(restaurant: Restaurant) {
        let subtitleParts = [restaurant.cuisine, restaurant.area, String(repeating: "$", count: max(1, min(4, restaurant.priceLevel)))]
        self.init(
            id: restaurant.id,
            name: restaurant.name,
            subtitle: subtitleParts.filter { !$0.isEmpty }.joined(separator: " · "),
            ratingText: String(format: "%.1f", restaurant.rating),
            reviewText: Self.reviewText(for: restaurant.reviewCount),
            etaText: "\(restaurant.deliveryMinutes) min",
            feeText: "\(PriceFormatter.string(from: restaurant.deliveryFee)) delivery",
            symbolName: restaurant.imageName,
            tint: UIColor(hex: restaurant.colorHex),
            isOpen: restaurant.isOpen,
            tags: restaurant.tags
        )
    }

    private static func reviewText(for count: Int) -> String {
        switch count {
        case ..<1: return ""
        case 1..<1000: return "(\(count))"
        default: return "(\(String(format: "%.1f", Double(count) / 1000))k)"
        }
    }
}
