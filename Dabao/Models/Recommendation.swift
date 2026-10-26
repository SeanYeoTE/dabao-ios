import Foundation

/// One suggested restaurant, with a short "why" for the UI.
nonisolated struct Recommendation: Hashable, Sendable {
    let restaurantID: String
    let score: Double
    let reason: String?
}
