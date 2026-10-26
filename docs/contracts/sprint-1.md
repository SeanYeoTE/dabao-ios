# Contract: restaurants, cart, history, recommendations

This contract is frozen. It covers sprint 1 (catalogue, browse, menu, cart, persistence, design system) and the
APIs sprint 2 builds on (history, recommender, extra components). [sprint-2.md](./sprint-2.md) adds the
sprint 2 behaviour and the expected ranking example.

## Ground rules

- Swift 6 language mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, approachable concurrency.
  - Plain data types are `nonisolated struct … : Sendable`.
  - Stores are `@MainActor final class` singletons (`static let shared`).
  - Background work uses `Task.detached` on `Sendable` values, and its results come back to the main actor.
- Synchronized folders: new `.swift` and `.json` files under `Dabao/` are compiled and bundled automatically. Never put `.md` or `.sh` files under `Dabao/`.
- Money is `Decimal`. Format it with `PriceFormatter.string(from:)`.
- No `print`. Use `os.Logger(subsystem: "com.tinkercademy.dabao", category: …)`.
- No force-unwraps on data paths.
- Keep the existing course style: short doc comments that explain *why*.
- No third-party delivery brand names, logos or mascots. Check with `grep -rIinE '\bp[a]nda\b|foodp[a]nda' --exclude-dir=.git .` (the brackets stop the pattern matching itself; a plain search would also match "Pandan").
- XCTest is out of scope. Leave `DabaoTests` compiling: keep the memberwise-style initialisers that `MenuPresenterTests` uses.

## Ownership

| Role | Owns |
|---|---|
| Backend | `Dabao/Models/**`, `Dabao/Services/**`, `Dabao/Resources/**`, `scripts/gen_catalogue.py` |
| Designer | `Dabao/DesignSystem/**`, `Dabao/Features/Splash/**`, `Dabao/Assets.xcassets/**`, `docs/design/**` |
| Frontend | `Dabao/App/**`, every other `Dabao/Features/**`, `DabaoTests/**` (compile fixes only) |
| PM | `docs/contracts/**`, `README.md`, `.gitignore`, `Dabao.xcodeproj/**`, `Dabao-Info.plist` |

## Backend API (`Dabao/Models`, `Dabao/Services`)

### Models

```swift
nonisolated struct MenuItem: Codable, Hashable, Identifiable, Sendable {
    let id: String; let name: String; let description: String
    let price: Decimal            // rounded to 2 dp on decode
    let category: String; let isSoldOut: Bool; let isSpicy: Bool
    let tags: [String]            // new; decodeIfPresent ?? []
    init(id:name:description:price:category:isSoldOut:isSpicy:tags: [String] = [])
}

nonisolated struct Restaurant: Codable, Hashable, Identifiable, Sendable {
    let id, name, cuisine: String; let rating: Double; let deliveryMinutes: Int
    let deliveryFee: Decimal; let isOpen: Bool; let imageName: String /* SF Symbol */; let menu: [MenuItem]
    // new, all decodeIfPresent with defaults:
    let tags: [String]; let description: String; let area: String
    let reviewCount: Int; let priceLevel: Int /* 1...4 */; let colorHex: String /* "#RRGGBB" */
    init(id:name:cuisine:rating:deliveryMinutes:deliveryFee:isOpen:imageName:menu:
         tags: [String] = [], description: String = "", area: String = "",
         reviewCount: Int = 0, priceLevel: Int = 1, colorHex: String = "#D70F64")
}

nonisolated struct CartLine: Hashable, Identifiable, Sendable {
    let id: UUID; let item: MenuItem; var quantity: Int; var notes: String
    var subtotal: Decimal { get }
    init(id: UUID = UUID(), item: MenuItem, quantity: Int, notes: String = "")
}

nonisolated struct PastOrderLine: Codable, Hashable, Identifiable, Sendable {
    let id: UUID; let menuItemID: String; let name: String
    let unitPrice: Decimal; let quantity: Int; let notes: String
    var subtotal: Decimal { get }
}

nonisolated struct PastOrder: Codable, Hashable, Identifiable, Sendable {
    let id: UUID; let placedAt: Date
    let restaurantID: String; let restaurantName: String; let cuisine: String
    let imageName: String; let colorHex: String
    let lines: [PastOrderLine]
    let subtotal: Decimal; let deliveryFee: Decimal; let total: Decimal
    var itemCount: Int { get }
}

nonisolated struct PersistedCartLine: Codable, Sendable {
    let id: UUID; let restaurantID: String; let menuItemID: String; let quantity: Int; let notes: String
}

nonisolated struct AppState: Codable, Sendable {
    static let currentSchemaVersion = 1
    var schemaVersion: Int; var cart: [PersistedCartLine]; var history: [PastOrder]  // history newest first
    static let empty: AppState
}

nonisolated struct Recommendation: Hashable, Sendable {
    let restaurantID: String; let score: Double; let reason: String?
}
```

### `CatalogStore` (`Services/CatalogStore.swift`)

It replaces `RestaurantService`, which is deleted in `s1-be-remove-legacy`. `RestaurantServicing` stays and `CatalogStore` conforms to it.

```swift
@MainActor final class CatalogStore: RestaurantServicing {
    static let shared: CatalogStore
    enum CatalogError: Error { case fileNotFound, invalid(String) }
    private(set) var restaurants: [Restaurant]        // catalogue order; [] until loaded
    var isLoaded: Bool { get }
    var cuisines: [String] { get }                    // unique, sorted A–Z
    func load(bundle: Bundle = .main, completion: @escaping (Result<[Restaurant], Error>) -> Void)
        // reads restaurants.json and decodes + validates in Task.detached; caches; later calls return the cache
        // validation: unique restaurant ids, unique item ids, every price > 0, every restaurant has >= 1 item
        // simulated 0.4 s delay unless LaunchOptions.noDelay
    func fetchRestaurants(completion:)                // = load
    func restaurants(cuisine: String?, query: String) -> [Restaurant]
        // cuisine nil = all; query trimmed, case/diacritic-insensitive, matches name, cuisine, tags, area,
        // menu item names and item tags; empty query = no filter; keeps catalogue order
    func restaurant(id: String) -> Restaurant?
}
```

### `CartStore` (`Services/CartStore.swift`, extended)

Keep the existing API: `restaurant`, `lines`, `itemCount`, `subtotal`, `deliveryFee`, `total`, `quantity(of:)`, `add(_:from:) -> Bool`, `remove(_:)`, `removeLine(at:)`, `clear()`, `maxQuantityPerItem`, `didChangeNotification`. Add:

```swift
enum AddResult: Equatable { case added, restaurantClosed, soldOut, limitReached(Int), differentRestaurant(currentName: String) }
func tryAdd(_ item: MenuItem, from restaurant: Restaurant) -> AddResult   // never clears another restaurant's cart
func replaceCart(with item: MenuItem, from restaurant: Restaurant)        // clear, then add 1 (still respects open/sold out)
func setQuantity(lineID: UUID, to quantity: Int)                          // clamps to 0...max; 0 removes the line
func removeLine(id: UUID)
func setNotes(lineID: UUID, to notes: String)                             // trimmed, max 140 chars
func line(id: UUID) -> CartLine?
func restore(_ lines: [PersistedCartLine], catalog: CatalogStore)          // drops unknown ids (logged); no save
var persisted: [PersistedCartLine] { get }
```

- When the cart empties, `restaurant` becomes nil.
- Every mutation posts `didChangeNotification` and calls `PersistenceController.shared.scheduleSave()`.
- The legacy `add(_:from:)` keeps its old meaning (it replaces the cart silently). New UI uses `tryAdd`.

### `HistoryStore` (`Services/HistoryStore.swift`), built in sprint 2 (stub in sprint 1)

```swift
@MainActor final class HistoryStore {
    static let shared: HistoryStore
    static let didChangeNotification: Notification.Name
    private(set) var orders: [PastOrder]               // newest first
    @discardableResult func place(cart: CartStore, now: Date = Date()) -> PastOrder?  // nil if cart empty; snapshots, inserts at 0, clears cart, saves
    func order(id: UUID) -> PastOrder?
    func replaceAll(_ orders: [PastOrder])              // restore and fixtures; sorts newest first; no save
}
```

### `PersistenceController` (`Services/PersistenceController.swift`)

```swift
@MainActor final class PersistenceController {
    static let shared: PersistenceController
    let fileURL: URL                // Application Support/Dabao/state.json (directory created on demand)
    func loadState() -> AppState    // missing file -> .empty; undecodable or newer schema -> move to
                                    // state.corrupt-<unix time>.json beside it, log, return .empty
    func scheduleSave()             // debounce 0.3 s; snapshot CartStore.persisted + HistoryStore.orders on main;
                                    // encode + write (.atomic) on a background queue
    func flush()                    // cancel the debounce and write synchronously now
    func reset()                    // delete state.json
}
```

JSON encoding uses `.prettyPrinted, .sortedKeys` and `.iso8601` dates, so QA can read it with `jq`. `Decimal` values encode as JSON numbers.

### `LaunchOptions` (`Services/LaunchOptions.swift`)

```swift
nonisolated enum LaunchOptions {
    static var reset: Bool        // "-dabaoReset" present in ProcessInfo.arguments
    static var skipSplash: Bool   // "-dabaoSkipSplash"
    static var noDelay: Bool      // "-dabaoNoDelay"
    static var fixture: String?   // the argument after "-dabaoFixture"
}
```

### `AppBootstrap` (`Services/AppBootstrap.swift`)

```swift
@MainActor enum AppBootstrap {
    /// 1. reset -> PersistenceController.reset()  2. CatalogStore.load  3. loadState -> HistoryStore.replaceAll,
    /// CartStore.restore  4. apply fixture (overrides restored state, then saves)  5. Recommender.shared.prepare(restaurants:)
    /// Calls completion on main once (with the catalogue error if loading failed).
    static func start(completion: @escaping (Error?) -> Void)
}
```

### Fixtures (`Services/Fixtures.swift`)

Each fixture replaces the cart and history, then saves.

| Name | Cart | History |
|---|---|---|
| `empty` | empty | empty |
| `cart-chicken-rice` | r1: 2 × `r1m1`, 1 × `r1m5` | empty |
| `history-laksa` | empty | 3 orders at the **first** restaurant tagged `laksa`. Each has its laksa dish × 1–2. Placed 1, 2 and 3 days before now. |
| `history-mixed` | empty | Newest first: an order at a laksa stall, r1 chicken rice, an Indian stall, r2 Mala Mama. Days 1–4. |

### `Recommender` (`Services/Recommender.swift`)

```swift
@MainActor final class Recommender {
    static let shared: Recommender
    static let didUpdateNotification: Notification.Name     // posted when the index is ready
    var isReady: Bool { get }
    func prepare(restaurants: [Restaurant])                  // builds the TF-IDF index in Task.detached
    func recommendations(history: [PastOrder], limit: Int = 10) -> [Recommendation]
    nonisolated static func tokenize(_ text: String) -> [String]
}
```

The algorithm is specified in sprint-2.md. In sprint 1, a stub that returns the cold-start ordering is fine.

### Catalogue (`scripts/gen_catalogue.py` → `Dabao/Resources/restaurants.json`)

- Python 3.9 standard library only. Uses `random.Random(20261026)`, a sorted, stable output order, and `json.dump(indent=2, ensure_ascii=False)`. The output must be byte-identical on every run.
- **100 restaurants**, IDs `r1`…`r100`.
  - `r1`–`r5` are copied from the current file with the same names, menus and item IDs, plus the new fields. `r4` and `r5` get extra items (new IDs, for example `r4m4`) so every restaurant has 6–12 items.
  - `r6`–`r100` are fictional Singapore hawker stalls and restaurants. No real chains.
- At least 10 cuisines, including Hawker, Peranakan, Malay, Indian, Chinese, Sichuan, Japanese, Korean, Thai, Western, Desserts and Coffee shop.
- At least 6 restaurants tagged `laksa`, with at least 3 of them cuisine `Peranakan`. Their laksa items have "Laksa" in the name and the tag `laksa`.
- About 8% of restaurants are closed (`r4` stays closed) and about 5% of items are sold out.
- Ratings are 3.6–4.9 (1 dp); `reviewCount` is 20–3000; delivery is 15–45 minutes; the fee is 0.99–4.99 (2 dp); `priceLevel` is 1–4.
- `imageName` must be a valid SF Symbol, for example `fork.knife`, `cup.and.saucer.fill`, `takeoutbag.and.cup.and.straw.fill`, `birthday.cake.fill`, `leaf.fill`, `flame.fill` or `fish.fill`.
- `colorHex` comes from a curated palette.
- Item prices are 0.80–28.00, rounded to 0.05. Categories are drawn from Mains, Sides, Drinks, Desserts, Snacks, Noodles, Rice and Sets.

## Design system API (`Dabao/DesignSystem`)

```swift
extension UIColor { convenience init(hex: String) }      // "#RRGGBB"; falls back to DS.Color.brand on bad input
enum DS {
    enum Color {  // dynamic light/dark UIColors
        static let brand        // #D70F64 light / #FF3D87 dark
        static let brandPressed, onBrand /* white */, background, surface, surfaceElevated,
                   textPrimary, textSecondary, textTertiary, separator, success, warning, danger,
                   chipBackground, chipText, chipSelectedBackground /* brand */, chipSelectedText /* white */
    }
    enum Font {   // Dynamic Type: UIFontMetrics-scaled; adjustsFontForContentSizeCategory = true on labels
        static var largeTitle, title, title2, headline, body, bodyBold, callout, subheadline, footnote, caption: UIFont { get }
    }
    enum Radius { static let card: CGFloat = 14, small: CGFloat = 8, button: CGFloat = 24 }
    enum Spacing { static let xxs: CGFloat = 2, xs = 4, s = 8, m = 12, l = 16, xl = 24, xxl = 32 }
    static let minTapTarget: CGFloat = 44
    static func applyGlobalAppearance()   // navigation bar, tab bar (brand selected tint), UISwitch/accent tint
}
```

### Components

All components are UIKit, use Auto Layout and tokens only, support Dynamic Type at AX5 (labels wrap, stacks switch to vertical when `traitCollection.preferredContentSizeCategory.isAccessibilityCategory`), and set VoiceOver labels.

```swift
struct RestaurantCardModel: Hashable {
    let id: String; let name: String; let subtitle: String      // "Peranakan · Katong · $$"
    let ratingText: String; let reviewText: String              // "4.6", "(1.2k)"
    let etaText: String; let feeText: String                    // "25 min", "$2.99 delivery"
    let symbolName: String; let tint: UIColor; let isOpen: Bool; let tags: [String]
}
final class RestaurantCardCell: UITableViewCell { static let reuseIdentifier: String; func configure(_ model: RestaurantCardModel) }
  // white rounded card, inset by DS.Spacing.l, tinted symbol tile on the left, "Closed" badge when !isOpen

final class ChipBar: UIView {                                   // horizontally scrolling pill chips
    var onSelect: ((String?) -> Void)?                          // tapping the selected chip deselects -> nil
    func setChips(_ titles: [String], selected: String?)
}

final class StickyCartBar: UIControl {                          // brand pill, height >= 56; hidden when count == 0 is the caller's job
    var onTap: (() -> Void)?
    func configure(itemCount: Int, totalText: String, title: String = "View cart")
}

final class QuantityControl: UIControl {                        // [−] n [+], each button 44×44
    var value: Int; var minimumValue: Int = 0; var maximumValue: Int = 10
    var onChange: ((Int) -> Void)?                              // also sends .valueChanged
}

final class PriceSummaryView: UIView {
    func configure(rows: [(title: String, value: String)], totalTitle: String, totalValue: String)
}

final class EmptyStateView: UIView {
    init(symbolName: String, title: String, message: String, actionTitle: String? = nil)
    var onAction: (() -> Void)?
}

final class SectionHeaderView: UITableViewHeaderFooterView { static let reuseIdentifier: String; func configure(title: String) }

final class PrimaryButton: UIButton {                           // brand filled pill, height >= 50
    init(title: String)
}

enum Toast { static func show(_ message: String, in view: UIView) }   // bottom pill, auto-hides after 2 s; posts a VoiceOver announcement

final class SplashViewController: UIViewController {          // Features/Splash
    init(onFinish: @escaping () -> Void)
    // brand background, white "dabao" wordmark + bag symbol; finishes after ~0.8 s or immediately with
    // Reduce Motion (no animation); the caller also decides when the app is ready
}
```

Sprint 2 components, built by the designer in sprint 2:

```swift
struct ForYouItem: Hashable { let card: RestaurantCardModel; let reason: String? }
final class ForYouCarouselView: UIView {                         // horizontal UICollectionView with a diffable data source keyed by card.id
    var onSelect: ((String) -> Void)?                           // restaurant id
    func setItems(_ items: [ForYouItem])                        // uses reconfigureItems for changes
}
struct OrderHistoryCellModel: Hashable {
    let id: UUID; let restaurantName: String; let dateText: String
    let itemsSummary: String; let totalText: String; let symbolName: String; let tint: UIColor
}
final class OrderHistoryCell: UITableViewCell { static let reuseIdentifier: String; func configure(_ model: OrderHistoryCellModel) }
final class ReceiptHeaderView: UIView { func configure(restaurantName: String, dateText: String, symbolName: String, tint: UIColor) }
final class ReceiptLineCell: UITableViewCell { static let reuseIdentifier: String; func configure(quantityText: String, name: String, notes: String?, priceText: String) }
```

## Frontend (`Dabao/App`, `Dabao/Features`)

- **`SceneDelegate`**
  - Calls `DS.applyGlobalAppearance()`.
  - Shows `SplashViewController` (skipped when `LaunchOptions.skipSplash`) while `AppBootstrap.start` runs, then swaps to `MainTabBarController`.
  - Calls `PersistenceController.shared.flush()` in `sceneDidEnterBackground`.
- **Tabs:** Home ("Home", `house.fill`), Cart (`bag.fill`, item count badge), Orders (`receipt`, sprint 2; a placeholder `EmptyStateView` in sprint 1), About.
  - `MenuRouter.showCart` finds the Cart tab by type, not by index.
- **Home** (`Features/RestaurantList`, MVC extended)
  - `UISearchController` that keeps the large title, a `ChipBar` header with an "All" chip, and a list of `RestaurantCardCell` driven by `UITableViewDiffableDataSource<Section, String>` (restaurant IDs).
  - An empty state when nothing matches.
  - A `StickyCartBar` pinned above the tab bar when the cart isn't empty.
  - Sprint 2: a "For you" carousel in the table header.
- **Menu** (`Features/Menu`, VIPER extended)
  - Header with name, cuisine, area, rating, review count, ETA, fee and description.
  - Sections use `SectionHeaderView`.
  - `MenuInteractor.addItem` uses `cart.tryAdd`. `.differentRestaurant(name)` → `output.didRequestReplaceCart(currentRestaurantName:itemID:)` → presenter → `view.showReplaceCartConfirmation(currentRestaurantName:onReplace:)`. Replace → `interactor.replaceCart(withItemID:)`.
  - Keep the closed and sold-out rules and messages.
  - Update the fakes in `MenuPresenterTests` so the test target still compiles. Don't run it.
- **Cart** (`Features/Cart`, MVC extended)
  - `UITableViewDiffableDataSource` keyed by line `UUID`, with `reconfigureItems` when lines change.
  - Each row shows the item name, a notes preview, the line price and a `QuantityControl`.
  - Swipe to delete. Tapping a row edits its notes in an alert with a text field.
  - Footer `PriceSummaryView` (subtotal, delivery, total), and `EmptyStateView` when empty.
  - Sprint 2: a `PrimaryButton` "Place order".
- All restaurant colours and symbols come from `Restaurant.colorHex` / `imageName` via `UIColor(hex:)`.

## Test cases (manual / serve-sim smoke)

TC-S1-1 … TC-S1-9 as listed in the plan. Launch for checks with
`xcrun simctl launch <udid> com.tinkercademy.dabao -dabaoSkipSplash -dabaoNoDelay -dabaoFixture <name>`.
State JSON lives at `$(xcrun simctl get_app_container <udid> com.tinkercademy.dabao data)/Library/Application Support/Dabao/state.json`.
