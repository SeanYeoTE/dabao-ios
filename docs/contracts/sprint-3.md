# Sprint 3 contract: floating "order on the way" bar

The ground rules, ownership and commit rules from [sprint-1.md](./sprint-1.md) still apply: Swift 6 with MainActor default isolation, `Decimal` money, no `print`, no force-unwraps on data paths, explicit pathspecs, and `[task-id] summary` plus the Co-authored-by trailer. Don't run XCTest, but keep `DabaoTests` compiling.

## Ideation outcome (decisions)

The PM chose these defaults when the user wasn't available.

| Question | Decision |
|---|---|
| Style | A slim floating pill showing a symbol tile, the stage and ETA ("On the way · 12 min"), the restaurant name, a thin progress line and a chevron |
| Where | Every tab, and also on pushed restaurant (Menu) pages. Hidden on the Order tracking screen of the order it shows, and hidden when there's no active order |
| With the View cart bar | They stack. The order bar sits at the very bottom, just above the tab bar or the home indicator, and the cart bar sits above it |
| Several active orders | The bar shows the most recent one with a "+N" badge. Tapping it opens the most recent one |
| Tap | Pushes a new **Order tracking** VIPER screen: big ETA, stage timeline, restaurant, items and total |
| Timeline | Simulated on the device from `placedAt` and the restaurant's `deliveryMinutes`. The launch argument `-dabaoFastDelivery` makes 1 minute last 1 second, for demos and QA |
| Arrival | The bar shows "Delivered" with a checkmark for 4 s, then hides. There's also the toast "Your order from <name> has arrived" |
| Persistence | Status is never stored. It's calculated from the clock, so it survives kill and relaunch |
| Out of scope | Maps, rider details, cancelling, push or local notifications, Live Activities |

## Backend (`Dabao/Models`, `Dabao/Services`)

```swift
// PastOrder: add a field (decodeIfPresent; nil for old saved orders -> treated as already delivered)
let deliveryMinutes: Int?
// keep a memberwise-style init where deliveryMinutes defaults to nil, so existing call sites compile

nonisolated enum DeliveryStage: Int, CaseIterable, Comparable, Sendable {
    case confirmed, preparing, onTheWay, delivered
    var title: String { get }      // "Order confirmed", "Preparing your food", "On the way", "Delivered"
    var shortTitle: String { get } // "Confirmed", "Preparing", "On the way", "Delivered"
}

nonisolated struct DeliveryStatus: Equatable, Sendable {
    let orderID: UUID
    let stage: DeliveryStage
    let progress: Double            // 0...1 across the whole delivery
    let minutesRemaining: Int       // ceil, >= 0; 0 when delivered
    let estimatedArrival: Date
    /// Pure function of time; `minuteLength` is 60 normally, 1 with -dabaoFastDelivery.
    static func make(for order: PastOrder, now: Date, minuteLength: TimeInterval) -> DeliveryStatus
}
```

### Timeline rule

- Let T be `deliveryMinutes`. If it's nil, the order counts as delivered.
- The total delivery takes `T × minuteLength` seconds, and progress p = elapsed / total.
- The stage follows p:
  - **confirmed** while p < 0.10
  - **preparing** while 0.10 ≤ p < 0.45
  - **onTheWay** while 0.45 ≤ p < 1
  - **delivered** once p ≥ 1
- `estimatedArrival = placedAt + total`.

### `DeliveryTracker` (`Services/DeliveryTracker.swift`)

```swift
@MainActor final class DeliveryTracker {
    static let shared: DeliveryTracker
    static let didChangeNotification: Notification.Name          // active statuses changed (posted at most once per tick when something changed)
    static let didDeliverNotification: Notification.Name         // userInfo["orderID"]: UUID; posted once per order, only for deliveries observed while running
    var minuteLength: TimeInterval { get }                       // LaunchOptions.fastDelivery ? 1 : 60
    private(set) var active: [DeliveryStatus]                    // undelivered, newest order first
    func status(for orderID: UUID) -> DeliveryStatus?
    func start()                                                 // observes HistoryStore changes; 1 s timer only while `active` is non-empty
    func refresh(now: Date = Date())
}
```

- When the app launches, orders that are already delivered never post `didDeliverNotification`.
- `HistoryStore.place` stores `deliveryMinutes` from `cart.restaurant`.
- `AppBootstrap` calls `DeliveryTracker.shared.start()` after restoring state.
- `LaunchOptions.fastDelivery` reads `-dabaoFastDelivery`.

### New fixtures (`Fixtures.names`)

| Name | Cart | History |
|---|---|---|
| `order-on-the-way` | empty | `history-mixed` plus one new order at r1, placed so it's at p ≈ 0.5 ("On the way") using the current `minuteLength` |
| `two-active-orders` | r2: 1 × its first available item | Like `order-on-the-way`, plus an older active order at r3 at p ≈ 0.2 ("Preparing") |

Without `-dabaoFastDelivery`, these orders stay active for minutes, which is enough for screenshot checks.

## Designer (`Dabao/DesignSystem`)

```swift
struct OrderStatusBarModel: Hashable {
    let symbolName: String; let tint: UIColor
    let title: String           // "On the way · 12 min" / "Preparing · 20 min" / "Delivered"
    let subtitle: String        // restaurant name
    let progress: Double        // 0...1
    let extraCount: Int         // 0 hides the "+N" badge
    let isDelivered: Bool       // checkmark tile, success tint, no chevron
}
final class OrderStatusBar: UIControl {
    var onTap: (() -> Void)?
    func configure(_ model: OrderStatusBarModel, animated: Bool)
}
```

- `OrderStatusBar` is a surface-coloured elevated pill: corner radius `DS.Radius.card`, a shadow and a brand-coloured progress line along the bottom.
- It's at least 56 pt tall, grows at accessibility text sizes and never clips.
- VoiceOver treats it as a button. Its label reads like "Order from Ah Seng, on the way, about 12 minutes, 1 more order", with the hint "Shows order tracking".
- Progress animations are skipped when Reduce Motion is on.

```swift
final class DeliveryTimelineView: UIView {            // vertical stepper: Confirmed → Preparing → On the way → Delivered
    func configure(stages: [String], currentIndex: Int, animated: Bool)  // done = filled brand dot + check, current = pulsing ring (static with Reduce Motion), future = grey
}
```

## Frontend (`Dabao/App`, `Dabao/Features`)

### Floating bar host (`MainTabBarController` or a small helper in `Dabao/App`)

- Adds an `OrderStatusBar` above the tab bar's content, with 16 pt side insets. It stays visible across tab switches and pushes.
- Its bottom sits `DS.Spacing.s` above the top of the tab bar while the tab bar is visible. When the top view controller hides the bottom bar (Menu), it sits above the bottom safe area instead.
- It follows push and pop transitions, using the transition coordinator or re-laying out in `viewDidLayoutSubviews`.
- While the bar shows, it sets `additionalSafeAreaInsets.bottom = barHeight + DS.Spacing.s` on each tab's navigation controller. That moves the existing cart bars (pinned to the safe area) and the table insets up automatically, so the two bars stack and nothing gets covered. The inset is set back to 0 when the bar hides.
- The bar is hidden when there are no active orders, and also when the top view controller is the `OrderTrackingViewController` for the order the bar shows.
- It updates on `DeliveryTracker.didChangeNotification`.
  - On `didDeliverNotification`: show the delivered state for 4 s, then hide (unless another order is active), and call `Toast.show("Your order from <name> has arrived", in: view)`.
- Tap pushes `OrderTrackingRouter.createModule(orderID:)` on the selected navigation controller.

### `Features/OrderTracking` (VIPER, same pattern as `Features/Receipt`)

- Files: `OrderTrackingContracts.swift`, `OrderTrackingViewController.swift`, `OrderTrackingInteractor.swift`, `OrderTrackingPresenter.swift`, `OrderTrackingRouter.swift`.
- `hidesBottomBarWhenPushed = true`, and the title is "Your order".
- The screen shows, in order:
  1. A header with the restaurant symbol tile, the restaurant name and a large "Arriving in 12 min" (or "Arrived" when delivered), plus the estimated arrival time ("Estimated 6:42 PM").
  2. The `DeliveryTimelineView`.
  3. Item lines (`ReceiptLineCell`) and a `PriceSummaryView`.
- It updates live from the tracker. Once the order is delivered, the screen shows the delivered state.

### Orders tab

- Active orders show their stage in the cell subtitle, for example "On the way · 12 min".
- Tapping an active order opens Order tracking. Delivered orders still open the Receipt.

## QA (TC-S3)

Run on the booted simulator with `-dabaoSkipSplash -dabaoNoDelay`.

1. With `order-on-the-way`, Home shows the bar "On the way · N min" with the r1 name above the tab bar, and the restaurant list isn't covered.
2. Switching to the Cart, Orders and About tabs keeps the bar. Opening a restaurant keeps it, just above the home indicator, and the cart bar stacks above it after adding an item.
3. Tapping the bar opens Order tracking with the ETA and a 4-stage timeline. On that screen the bar is hidden; going back shows it again.
4. `two-active-orders` shows the "+1" badge.
5. With `-dabaoFastDelivery`, placing an order shows the bar, which moves through the stages. After about the restaurant's `deliveryMinutes` in seconds, the toast "Your order from … has arrived" and the Delivered state appear, then the bar hides.
6. Kill and relaunch mid-delivery: the bar comes back with the same stage and ETA.
7. Largest accessibility text size and dark mode: no clipping, and the bars don't overlap.
8. The build is green, and the brand grep is clean.
