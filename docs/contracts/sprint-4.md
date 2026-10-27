# Sprint 4 contract: delivery map on the tracking screen

The ground rules, ownership and commit rules from [sprint-1.md](./sprint-1.md) still apply. This builds on [sprint-3.md](./sprint-3.md).

## Decisions

| Topic | Decision |
|---|---|
| Where | A map at the top of the **Your order** screen only. The floating bar doesn't change |
| Locations | Fixed. Each restaurant's coordinate comes from its `area`, with a small, repeatable offset per restaurant id. The delivery address is fixed: **Home · Ngee Ann Polytechnic**, 535 Clementi Rd (1.33310, 103.77640) |
| GPS | None. No CoreLocation, no permission prompt and no `Info.plist` changes |
| Routing | `MKDirections` (driving) between the two fixed points, with an 8 s timeout and the result cached in memory per order. If it fails, is offline, or `-dabaoOfflineMap` is set, fall back to a curved path drawn on the device |
| Rider | Simulated. During Confirmed and Preparing the rider waits at the restaurant (no rider marker; the restaurant marker pulses). During On the way it moves along the route by distance; the fraction is (p − 0.45) / 0.55. When the order is Delivered, the rider is at home |
| Accessibility | The map is one VoiceOver element. Its label reads like "Map. Rider is 1.2 km away, on the way from Ah Seng Chicken Rice to Home". The same distance is shown as text under the ETA |

## Backend (`Dabao/Models`, `Dabao/Services`)

```swift
// PastOrder: add `let restaurantArea: String?` (decodeIfPresent, init default nil); HistoryStore.place and fixtures fill it.

nonisolated struct GeoPoint: Codable, Hashable, Sendable { let latitude: Double; let longitude: Double }

nonisolated enum DeliveryLocations {
    static let home: GeoPoint                       // 1.33310, 103.77640
    static let homeName: String                     // "Home · Ngee Ann Polytechnic"
    static func coordinate(forArea area: String?, restaurantID: String) -> GeoPoint
        // a table covering every area in restaurants.json (about 30 Singapore neighbourhoods, approximate centres);
        // unknown or nil area -> Singapore centre (1.3000, 103.8500). Adds a stable offset of up to ±0.004° from a
        // simple stable hash of restaurantID (NOT Swift's hashValue, which is randomised per launch)
}

nonisolated struct DeliveryRoute: Equatable, Sendable {
    let points: [GeoPoint]                          // >= 2, restaurant first, home last
    let distanceMeters: Double                      // the route length
    let isApproximate: Bool                         // true for the curved fallback
    func point(atFraction f: Double) -> GeoPoint    // interpolates by distance, clamped to 0...1
    func remainingMeters(atFraction f: Double) -> Double
    static func fallback(from: GeoPoint, to: GeoPoint) -> DeliveryRoute   // quadratic Bézier, 32 points, control point offset 25% perpendicular
}

nonisolated struct RiderPosition: Equatable, Sendable {
    let coordinate: GeoPoint?                       // nil while the order is confirmed or preparing
    let remainingMeters: Double
    static func make(route: DeliveryRoute, status: DeliveryStatus) -> RiderPosition
}

@MainActor final class DeliveryRouteProvider {
    static let shared: DeliveryRouteProvider
    func route(for order: PastOrder, completion: @escaping (DeliveryRoute) -> Void)
        // on a cache hit, completes synchronously; otherwise calls MKDirections (unless LaunchOptions.offlineMap) with an
        // 8 s timeout and falls back on failure; always completes on main, exactly once
    func restaurantCoordinate(for order: PastOrder) -> GeoPoint
}
// LaunchOptions.offlineMap reads "-dabaoOfflineMap".
// Distance text helper: `nonisolated enum DistanceFormatter { static func string(meters: Double) -> String }`
// gives "850 m" under 1 km, otherwise "1.2 km".
```

## Designer (`Dabao/DesignSystem`)

```swift
import MapKit
final class DeliveryMapView: UIView {   // wraps MKMapView; plain values only (CLLocationCoordinate2D)
    func configure(restaurant: CLLocationCoordinate2D, restaurantSymbol: String, restaurantTint: UIColor,
                   home: CLLocationCoordinate2D, route: [CLLocationCoordinate2D], isApproximateRoute: Bool)
        // fits the route with padding; the route is a brand-coloured polyline, dashed when approximate
    func setRider(_ coordinate: CLLocationCoordinate2D?, animated: Bool)   // nil hides the rider; animation is skipped with Reduce Motion
    func setWaitingAtRestaurant(_ waiting: Bool)                           // the restaurant marker pulses while true (static with Reduce Motion)
    var accessibilitySummary: String { get set }                           // becomes the accessibilityLabel
}
```

- **Markers:**
  - The restaurant marker is a round tile showing the restaurant's symbol and tint.
  - The rider marker is a brand-coloured circle with `bicycle` (or `scooter`), plus a white ring and a shadow.
  - The home marker is `house.fill` on `DS.Color.textPrimary`.
- **Map:** muted standard map (`MKStandardMapConfiguration(emphasisStyle: .muted)`), points of interest hidden, user interaction allowed (pan and zoom) and rotation disabled. It works in dark mode, with corner radius `DS.Radius.card`.
- **Height:** a fixed 240 pt, or 200 pt at accessibility text sizes. The map doesn't scale with text.
- Add a short spec, `docs/design/screens-s4.md`.

## Frontend (`Dabao/Features/OrderTracking`)

- The view model gains `mapModel` (restaurant, home and route points as `GeoPoint`, the approximate flag, the restaurant symbol and tint hex) and `riderModel` (rider coordinate or nil, waiting flag, distance text and accessibility summary).
- The interactor requests the route from `DeliveryRouteProvider` once when it loads. On every tracker tick it recomputes `RiderPosition.make`, and the presenter formats the text.
- **Layout:** the map is at the top of the table header, above the restaurant name and ETA. Under the "Estimated …" line there's a new label:
  - "Rider is 1.2 km away" while On the way
  - "Waiting at restaurant" before that
  - "Delivered to Home" afterwards
- If the route is still loading, show the map with only the markers. Add the route when it arrives.
- The view converts `GeoPoint` to `CLLocationCoordinate2D`. The presenter doesn't import MapKit.
- Keep `DabaoTests` compiling.

## QA (TC-S4)

1. With `order-on-the-way`, the tracking screen shows a map and the text "Rider is X km away". X decreases over time with `-dabaoFastDelivery`.
2. With `two-active-orders`, the Kopi Corner order, which is still being prepared, shows "Waiting at restaurant".
3. With `-dabaoOfflineMap`, the screen still shows the route (the dashed fallback), and there's no crash or hang.
4. When the order is delivered, the text reads "Delivered to Home".
5. No location permission prompt appears, and the source has no `CLLocationManager`.
6. Dark mode and AX5: the map stays visible and the text below it wraps.
7. The build and `build-for-testing` are green, and the brand grep is clean.
