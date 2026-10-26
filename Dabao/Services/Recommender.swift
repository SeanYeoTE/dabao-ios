import Foundation

/// Suggests restaurants from what someone has ordered before.
///
/// Every restaurant becomes a TF-IDF vector over words (name, cuisine, tags, description, dishes).
/// An order history becomes a "taste profile": the vectors of the places you ordered from,
/// weighted by how much you ordered and how recently. Restaurants close to that profile rank first.
@MainActor
final class Recommender {

    static let shared = Recommender()

    /// Posted on the main actor when the index has been built.
    static let didUpdateNotification = Notification.Name("RecommenderDidUpdate")

    /// How much less each older order counts.
    private static let recencyDecay = 0.8
    /// Restaurants from the newest orders are shown less, so "For you" isn't just "order again".
    private static let recentOrderCount = 3
    private static let recentPenalty = 0.5

    nonisolated private static let stopwords: Set<String> = [
        "and", "the", "with", "of", "in", "a", "an", "set", "for", "to", "on", "our", "house", "special",
        "cup", "plate", "bowl", "side",
    ]

    private(set) var isReady = false

    private var restaurants: [Restaurant] = []
    private var index = Index(vectors: [:], sortedTerms: [:])
    private var generation = 0

    /// Builds the index off the main thread, then marks the recommender ready.
    func prepare(restaurants: [Restaurant]) {
        self.restaurants = restaurants
        isReady = false
        generation += 1
        let current = generation

        Task {
            let built = await Task.detached(priority: .userInitiated) {
                Recommender.buildIndex(for: restaurants)
            }.value
            // A newer prepare(restaurants:) call wins.
            guard current == generation else { return }
            index = built
            isReady = true
            NotificationCenter.default.post(name: Recommender.didUpdateNotification, object: self)
        }
    }

    /// `history` is newest first. Falls back to "Popular on Dabao" with no history or no index yet.
    func recommendations(history: [PastOrder], limit: Int = 10) -> [Recommendation] {
        guard limit > 0 else { return [] }
        let catalogue = restaurants.isEmpty ? CatalogStore.shared.restaurants : restaurants
        let open = catalogue.filter(\.isOpen)

        guard isReady, !history.isEmpty,
              let profile = makeProfile(history: history) else {
            return coldStart(open, limit: limit)
        }

        let recentIDs = Set(history.prefix(Recommender.recentOrderCount).map(\.restaurantID))
        let scored: [(restaurant: Restaurant, score: Double)] = open.compactMap { restaurant in
            guard let vector = index.vectors[restaurant.id],
                  let terms = index.sortedTerms[restaurant.id] else { return nil }
            var score = Recommender.cosine(profile, vector, terms: terms)
            if recentIDs.contains(restaurant.id) {
                score *= Recommender.recentPenalty
            }
            return (restaurant, score)
        }

        let top = scored.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return Recommender.idPrecedes(lhs.restaurant.id, rhs.restaurant.id)
        }.prefix(limit)

        return top.map { entry in
            Recommendation(restaurantID: entry.restaurant.id, score: entry.score,
                           reason: reason(for: entry.restaurant, history: history))
        }
    }

    /// Lowercase, accent-free words: split on anything that isn't a letter or digit, drop one-letter words
    /// and stopwords, and turn plurals into singulars ("noodles" -> "noodle", "berries" -> "berry").
    nonisolated static func tokenize(_ text: String) -> [String] {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        let words = folded.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        return words
            .filter { $0.count >= 2 && !stopwords.contains($0) }
            .map(stem)
    }

    // MARK: - Index

    private nonisolated struct Index: Sendable {
        /// Restaurant id -> L2-normalised TF-IDF vector.
        let vectors: [String: [String: Double]]
        /// Each vector's words in a fixed order, so floating point sums come out the same every run.
        let sortedTerms: [String: [String]]
    }

    nonisolated private static func buildIndex(for restaurants: [Restaurant]) -> Index {
        let documents = restaurants.map { (id: $0.id, tokens: documentTokens(for: $0)) }
        let total = Double(documents.count)

        var documentFrequency: [String: Int] = [:]
        for document in documents {
            for term in Set(document.tokens) {
                documentFrequency[term, default: 0] += 1
            }
        }

        var vectors: [String: [String: Double]] = [:]
        var sortedTerms: [String: [String]] = [:]
        for document in documents where !document.tokens.isEmpty {
            var counts: [String: Int] = [:]
            for token in document.tokens {
                counts[token, default: 0] += 1
            }
            let length = Double(document.tokens.count)
            let terms = counts.keys.sorted()
            var vector: [String: Double] = [:]
            var squares = 0.0
            for term in terms {
                let tf = Double(counts[term] ?? 0) / length
                let idf = log((total + 1) / (Double(documentFrequency[term] ?? 0) + 1)) + 1
                let weight = tf * idf
                vector[term] = weight
                squares += weight * weight
            }
            let norm = squares.squareRoot()
            guard norm > 0 else { continue }
            for term in terms {
                vector[term] = (vector[term] ?? 0) / norm
            }
            vectors[document.id] = vector
            sortedTerms[document.id] = terms
        }
        return Index(vectors: vectors, sortedTerms: sortedTerms)
    }

    /// Each field's tokens, repeated to give it weight: cuisine and tags count double.
    nonisolated private static func documentTokens(for restaurant: Restaurant) -> [String] {
        var tokens = tokenize(restaurant.name)
        let cuisine = tokenize(restaurant.cuisine)
        tokens += cuisine + cuisine
        for tag in restaurant.tags {
            let tagTokens = tokenize(tag)
            tokens += tagTokens + tagTokens
        }
        tokens += tokenize(restaurant.description)
        for item in restaurant.menu {
            tokens += tokenize(item.name)
            for tag in item.tags {
                tokens += tokenize(tag)
            }
        }
        return tokens
    }

    // MARK: - Ranking

    /// The sum of past restaurants' vectors, each scaled by items ordered and by 0.8^k (k = 0 is the newest).
    /// Nil when none of the orders are from restaurants we know.
    private func makeProfile(history: [PastOrder]) -> [String: Double]? {
        var profile: [String: Double] = [:]
        var weight = 1.0
        for order in history {
            defer { weight *= Recommender.recencyDecay }
            guard let vector = index.vectors[order.restaurantID],
                  let terms = index.sortedTerms[order.restaurantID] else { continue }
            let scale = Double(order.itemCount) * weight
            for term in terms {
                profile[term, default: 0] += (vector[term] ?? 0) * scale
            }
        }
        let magnitude = profile.values.reduce(0) { $0 + $1 * $1 }
        return magnitude > 0 ? profile : nil
    }

    /// Cosine similarity. `vector` is already unit length, so only the profile needs dividing.
    nonisolated private static func cosine(_ profile: [String: Double], _ vector: [String: Double],
                                           terms: [String]) -> Double {
        var dot = 0.0
        for term in terms {
            dot += (profile[term] ?? 0) * (vector[term] ?? 0)
        }
        var squares = 0.0
        for term in profile.keys.sorted() {
            let value = profile[term] ?? 0
            squares += value * value
        }
        let norm = squares.squareRoot()
        return norm > 0 ? dot / norm : 0
    }

    /// "Because you ordered X": the past dish that shares the most weight with this restaurant.
    private func reason(for restaurant: Restaurant, history: [PastOrder]) -> String? {
        if let vector = index.vectors[restaurant.id] {
            var best: (name: String, weight: Double)?
            // Newest first, and only a strictly higher weight replaces the best, so ties go to the newer order.
            for order in history {
                for line in order.lines {
                    let weight = Recommender.tokenize(line.name).reduce(0.0) { $0 + (vector[$1] ?? 0) }
                    if weight > (best?.weight ?? 0) {
                        best = (line.name, weight)
                    }
                }
            }
            if let best {
                return "Because you ordered \(best.name)"
            }
        }
        return history.first.map { "Similar to \($0.restaurantName)" }
    }

    private func coldStart(_ open: [Restaurant], limit: Int) -> [Recommendation] {
        let scored = open.map { ($0, $0.rating * log(1 + Double($0.reviewCount))) }
        let top = scored.sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return Recommender.idPrecedes(lhs.0.id, rhs.0.id)
        }.prefix(limit)
        return top.map { Recommendation(restaurantID: $0.0.id, score: $0.1, reason: "Popular on Dabao") }
    }

    /// Ids compare numerically, so "r2" comes before "r10".
    nonisolated private static func idPrecedes(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: .numeric) == .orderedAscending
    }

    nonisolated private static func stem(_ word: String) -> String {
        if word.hasSuffix("ies") {
            return String(word.dropLast(3)) + "y"
        }
        if word.count > 3, word.hasSuffix("s"), !word.hasSuffix("ss") {
            return String(word.dropLast())
        }
        return word
    }
}
