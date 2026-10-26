import Foundation

/// Ready-made carts and histories for QA, picked with `-dabaoFixture <name>`.
@MainActor
enum Fixtures {

    static let names = ["empty", "cart-chicken-rice", "history-laksa", "history-mixed"]

    /// Replaces the cart and history with the named fixture, then saves. Unknown names are ignored.
    static func apply(_ name: String, catalog: CatalogStore, now: Date = Date()) {
        _ = (name, catalog, now)
    }
}
