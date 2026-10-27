# Sprint 5 contract: Orders redesign with Reorder and inline rating

The ground rules, ownership and commit rules from [sprint-1.md](./sprint-1.md) still apply. This builds on
[sprint-3.md](./sprint-3.md) (delivery tracking) and [sprint-4.md](./sprint-4.md).

Branch: `feature/s5-reorder-rating` (from `main`). Agents commit and push only to this branch and never open PRs.

## Decisions

| Topic | Decision |
|---|---|
| Layout | The Orders tab has two sections. **Active orders**: orders in `DeliveryTracker.active`, shown with the existing `OrderHistoryCell` (status text, tap → Order tracking, no Reorder, no rating). **Past orders**: every delivered order, shown with the new `PastOrderCell`. A section with no rows is left out entirely (no header). The nav title stays "Orders". The empty state is unchanged |
| Past card | SF Symbol tile (no photos), restaurant name (up to 2 lines), total at the top right (`PriceFormatter`), "Delivered on 25 Oct, 21:27", items summary (up to 2 lines, e.g. "2 × Chicken Rice, 1 × Iced Tea"), a full-width `PrimaryButton` "Reorder", a hairline divider, then the rating footer. Tapping the card body (anywhere except the button and stars) opens the Receipt |
| Delivered time | `placedAt + deliveryMinutes × minuteLength`. Orders with nil or 0 `deliveryMinutes` use `placedAt` |
| Date formats | Fixed `en_GB` locale. Delivered line: `"Delivered on " + "d MMM, HH:mm"` → "Delivered on 25 Oct, 21:27". Deadline: `"dd MMM yyyy"` → "04 Dec 2026" |
| Rating | Tapping star *n* saves rating *n* (1–5) at once and persists it in `state.json`. It can be changed any number of times until the deadline |
| Rating window | **3 days** after the delivered time (`RatingPolicy.windowDays = 3`). Rating is allowed while `now < deadline` |
| Footer states | (a) In window, unrated: title "Tap to rate", subtitle "by 30 Oct 2026", 5 outline stars, editable. (b) In window, rated: title "You rated", subtitle "Change by 30 Oct 2026", *n* filled stars, editable. (c) Past the deadline, rated: title "You rated", no subtitle, *n* filled stars, read-only. (d) Past the deadline, unrated: no footer and no divider |
| Reorder: unavailable | Checked on tap; the button is always enabled. **Block** with an alert (single "OK" button, cart untouched) when: the restaurant is no longer in the catalogue; it's closed; or any line's item is missing from the menu or sold out. See the alert copy below |
| Reorder: cart conflict | If the plan is ready and the cart is non-empty (any restaurant), show "Replace your cart?" (Cancel / Replace). Cancel leaves the cart alone. Replace (or an empty cart) fills the cart and switches to the Cart tab |
| Reorder: contents | The same items, quantities and notes, at today's catalogue prices. Lines for the same item are merged (quantities added, first non-empty note kept). Quantities are clamped to `1...CartStore.maxQuantityPerItem`, notes to `CartStore.maxNotesLength` |
| Accessibility | The card body is one button element: "<name>, Delivered on …, <items>, Total <total>". The Reorder button is its own element, labelled "Reorder from <name>". The stars are **one adjustable element**, label "Rating", value "Not rated" or "4 of 5 stars", hint "Rate by 30 Oct 2026" (editable only); swiping up/down changes the rating by 1 (minimum 1). Read-only stars are a static element. Each star's hit area is at least 44 × 44 pt. At accessibility text sizes, the name/total header and the footer stack vertically |

### Alert copy (exact)

| Case | Title | Message | Buttons |
|---|---|---|---|
| Restaurant missing | "Restaurant unavailable" | "<restaurantName> is no longer on Dabao." | OK |
| Restaurant closed | "<restaurantName> is closed" | "You can reorder when it opens again." | OK |
| Items unavailable | "Some items are unavailable" | "Sold out or no longer on the menu: <A, B>." | OK |
| Cart conflict | "Replace your cart?" | "Your cart has items from <currentCartRestaurant>. Start a new cart from <restaurantName>?" | Cancel (cancel style), Replace (destructive style) |

## Backend (`Dabao/Models`, `Dabao/Services`)

```swift
// PastOrder (Models/PastOrder.swift)
//   add `var rating: Int?` (1...5; nil = unrated). Last stored property; the init gets `rating: Int? = nil` as its last
//   parameter so every existing call site keeps compiling. Synthesized Codable decodes a missing key as nil, so
//   state.json from earlier sprints still loads; AppState.currentSchemaVersion stays 1.
extension PastOrder {
    func deliveredAt(minuteLength: TimeInterval) -> Date
}

nonisolated enum RatingPolicy {
    static let windowDays = 3
    static func deadline(for order: PastOrder, minuteLength: TimeInterval) -> Date   // deliveredAt + 3 × 86 400 s
    static func canRate(_ order: PastOrder, now: Date, minuteLength: TimeInterval) -> Bool
        // true when the order is delivered (DeliveryStatus.make(...).stage == .delivered) and now < deadline
}

// HistoryStore
@discardableResult
func setRating(_ stars: Int, for orderID: UUID, now: Date = Date()) -> Bool
    // false (and no change) if the order is unknown, stars is outside 1...5, or !RatingPolicy.canRate(using
    // DeliveryTracker.shared.minuteLength). Otherwise updates the order in place (order of the list unchanged),
    // posts didChangeNotification and calls PersistenceController.shared.scheduleSave().

// Services/ReorderPlanner.swift
nonisolated struct ReorderLine: Equatable, Sendable {
    let item: MenuItem
    let quantity: Int      // already clamped
    let notes: String      // already clamped
}

nonisolated enum ReorderPlan: Equatable, Sendable {
    case ready(restaurant: Restaurant, lines: [ReorderLine])   // lines non-empty, in the order's line order
    case restaurantMissing(name: String)                        // name = the order's restaurantName snapshot
    case restaurantClosed(name: String)                         // name = the catalogue restaurant's name
    case itemsUnavailable(names: [String])                      // snapshot names, order of first appearance, no duplicates
}

enum ReorderPlanner {   // main actor (default isolation)
    static func plan(for order: PastOrder, catalog: CatalogStore = .shared) -> ReorderPlan
        // precedence: restaurantMissing, then restaurantClosed, then itemsUnavailable, then ready
}

// CartStore
func replaceCart(with lines: [ReorderLine], from restaurant: Restaurant)
    // empties the cart, sets the restaurant, appends the lines (skipping any sold-out item defensively), notifies once
    // and saves. An empty `lines` leaves an empty cart with restaurant nil.
```

### Fixture `history-rating`

Install with an **empty cart**. `now` is launch time; "h ago" means `placedAt = now − h hours`. All have
`deliveryMinutes` set (they're delivered long before `now`). Newest first after `replaceAll`:

| # | Restaurant | Placed | Lines | Rating | Expected |
|---|---|---|---|---|---|
| 1 | `r1` | 26 h ago | `r1m1` × 2, notes "Less rice"; `r1m5` × 1 | nil | footer (a); Reorder succeeds |
| 2 | first restaurant with `isOpen == false` | 30 h ago | its first menu item × 1 | nil | footer (a); Reorder → "… is closed" |
| 3 | first **open** restaurant that has at least one sold-out item | 50 h ago | that sold-out item × 1 and its first not-sold-out item × 1 | 4 | footer (b); Reorder → "Some items are unavailable" naming the sold-out item |
| 4 | `r2` | 5 days ago | `r2m1` × 1 | nil | footer (d): no footer |
| 5 | `r1` | 6 days ago | `r1m1` × 1 | 3 | footer (c): read-only 3 stars |

If any restaurant is missing, log via `missing(name)` like the other fixtures. Also add `history-rating` to the
fixture list in any doc comment that enumerates fixtures.

## Designer (`Dabao/DesignSystem`, `docs/design`)

Plain values only (no model types). Write `docs/design/screens-s5.md` (layout, spacing, states a–d, dark mode, AX5).

```swift
/// Five stars. Outline `star` in DS.Color.brand when empty, `star.fill` in DS.Color.brand when filled.
final class StarRatingView: UIView {
    var onSelect: ((Int) -> Void)?                     // 1...5; only called when editable
    func configure(rating: Int?, isEditable: Bool, deadlineText: String?)  // deadlineText feeds the a11y hint
    // One adjustable accessibility element when editable (see Decisions), static when read-only.
    // Each star is at least DS.minTapTarget square. Doesn't call onSelect when the tapped value equals the current rating.
}

struct RatingFooterModel: Hashable {
    let title: String           // "Tap to rate" | "You rated"
    let subtitle: String?       // "by 30 Oct 2026" | "Change by 30 Oct 2026" | nil
    let rating: Int?
    let isEditable: Bool
}

struct PastOrderCellModel: Hashable {
    let id: UUID
    let restaurantName: String
    let totalText: String
    let dateText: String        // "Delivered on 25 Oct, 21:27"
    let itemsSummary: String
    let symbolName: String
    let tint: UIColor
    let footer: RatingFooterModel?   // nil → no divider, no footer
}

final class PastOrderCell: CardTableViewCell {
    static let reuseIdentifier = "PastOrderCell"
    var onReorder: (() -> Void)?
    var onRate: ((Int) -> Void)?
    var onSelectBody: (() -> Void)?   // tap on the card body (not the button or the stars)
    func configure(_ model: PastOrderCellModel)
    // prepareForReuse clears the three closures.
}
```

`SectionHeaderView` is reused for "Active orders" and "Past orders" (`DS.Font.title2`); change it only if needed, and
keep its existing API.

Layout checks: the working tree is shared and synchronized folders compile everything under `Dabao/`, so **never
add a temporary test host**. Review constraints carefully (activate them only after views are in the hierarchy; no
conflicting required constraints between the AX5 and default layouts). The frontend and PM check the real screen on
the simulators.

## Frontend (`Dabao/Features/OrderHistory`, `Dabao/App`)

- `OrderHistoryViewController`: a two-section diffable data source (`active`, `past`), `SectionHeaderView` headers,
  `OrderHistoryCell` for active rows, `PastOrderCell` for past rows. Keep the "skip if nothing changed" guard (the
  tracker ticks every second). Card-body taps go through `onSelectBody`; don't rely on `didSelectRowAt` for past rows.
- Contracts (`OrderHistoryContracts.swift`), at least:
  - view: `showOrders(active: [OrderHistoryCellModel], past: [PastOrderCellModel])`, `showAlert(title:message:)`,
    `showReplaceCartConfirmation(title:message:onReplace:)` (or the router presents them; your call, but keep UIKit
    out of the presenter and interactor);
  - presenter: `didSelectOrder(id:)`, `didTapReorder(id:)`, `didRate(id:stars:)`;
  - interactor: `loadOrders()`, `reorderPlan(for:)`, `cartRestaurantName` (nil when the cart is empty),
    `applyReorder(_:)`, `rate(id:stars:)`;
  - router: `showReceipt(orderID:)`, `showTracking(orderID:)`, `showCart()` (uses `UIViewController.showCartTab()`).
- The interactor also refreshes on `HistoryStore.didChangeNotification` (it already does for history/tracker) so a
  rating change redraws the footer. The rating window is evaluated with `Date()` each time rows are built.
- Date formatting: add the en_GB "Delivered on" and deadline formatters next to `OrderDateFormatter` (active rows
  keep their current text).
- Exact strings from the Decisions and Alert copy tables.
- No debug hooks (no UserDefaults/env-driven navigation, no `TEMP` code). `DabaoTests` keeps compiling.

## Test cases (TC-S5)

Run on the QA simulator with `-dabaoSkipSplash -dabaoNoDelay -dabaoReset` and OCR.

| # | Fixture / flags | Steps | Expected |
|---|---|---|---|
| 1 | `history-rating` | Open Orders | "Past orders" header, no "Active orders". Order 1 shows "Delivered on …", "Reorder", "Tap to rate", "by <date ≈ 2 days from now>" |
| 2 | `history-rating` | Tap star 4 on order 1; relaunch without reset | Footer "You rated", "Change by …"; `state.json` order 1 has `"rating": 4`; persists after relaunch; tapping star 2 changes it to 2 |
| 3 | `history-rating` | Scroll to orders 4 and 5 | Order 4 has no footer. Order 5 shows "You rated" with no subtitle; tapping a star doesn't change `state.json` |
| 4 | `history-rating` | Tap Reorder on order 1 | Cart tab opens with the same items, quantities and the "Less rice" note |
| 5 | `cart-chicken-rice` → then `history-rating` cart non-empty (add an item from Home first) | Reorder order 1; Cancel; Reorder again; Replace | Alert copy exact; Cancel keeps the cart; Replace swaps it |
| 6 | `history-rating` | Reorder orders 2 and 3 | Closed and unavailable alerts with exact copy; cart unchanged |
| 7 | `order-on-the-way` + `-dabaoFastDelivery` | Open Orders, wait for delivery | "Active orders" section on top; tap → tracking; after delivery the order moves to "Past orders" with "Tap to rate" |
| 8 | `history-rating` | Tap the card body of order 1; dark mode and AX5; builds and greps | Receipt opens; layouts readable, nothing clipped; clean build and build-for-testing green; brand grep and debug-hook grep empty |
