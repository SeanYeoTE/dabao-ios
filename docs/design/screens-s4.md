# Design spec: sprint 4

Same tokens and rules as [screens-s1.md](./screens-s1.md). Behaviour is defined in [sprint-4.md](../contracts/sprint-4.md).

## `DeliveryMapView` (order tracking map)

```
┌──────────────────────────────────────────┐
│                          ╭ ─ ─ ─ ─ ─ ╮    │  muted standard map, no POIs
│   (tile)━━━━━━━━┓                          │  route: 5 pt brand polyline
│                 ┗━━━━(rider)━━━━━(home)    │
└──────────────────────────────────────────┘
```

- **API:** plain values only (`CLLocationCoordinate2D`, `String`, `UIColor`); no app model or MapKit types leak in. `configure(restaurant:restaurantSymbol:restaurantTint:home:route:isApproximateRoute:)`, `setRider(_:animated:)`, `setWaitingAtRestaurant(_:)`, `accessibilitySummary`. An optional `riderSymbol` ("bicycle" by default, or "scooter") picks the rider glyph.
- **Usage:** pin it to the table header with leading, trailing and top insets (it owns its own height constraint, priority 999). `configure` can be called again when the route arrives. The first call with only the markers (empty or one-point `route`) shows just the markers fitted on screen. Call `setRider(nil, animated: false)` to hide the rider.
- **Size:** fixed 240 pt tall, 200 pt at accessibility content sizes (AX1+). It does not scale with text; it updates on a trait change. Corner radius `DS.Radius.card`, clipped.
- **Map:** `MKStandardMapConfiguration(emphasisStyle: .muted)`, points of interest excluded, rotation and pitch disabled, pan and zoom allowed, no compass, no user location. Follows light and dark mode (the map and the markers adapt).
- **Fit:** the restaurant, the home and every route point are fitted with `setVisibleMapRect(_:edgePadding:)` (48 pt on the sides, 56 pt top, 40 pt bottom). If the view has no size yet, the fit is applied on the first layout.
- **Route:** `DS.Color.brand` polyline, 5 pt, round caps and joins. When `isApproximateRoute` is true it is dashed (10 on, 8 off, butt caps) so it reads as an estimate.
- **Markers** (all circles with a white or elevated ring and a soft shadow; z-order: rider above restaurant above home):

| Marker | Size | Look |
|---|---|---|
| Restaurant | 46 pt | `SymbolTileView`-style tile with the restaurant's symbol and tint on `surfaceElevated` |
| Rider | 40 pt | `brand` disc, white `bicycle` glyph, 3 pt white ring |
| Home | 36 pt | `textPrimary` disc, `house.fill` glyph in `surface` (so it reads in both modes), 3 pt white ring |

- **Rider movement:** `setRider(_, animated: true)` moves the marker with a 0.8 s linear `UIView.animate` on the annotation's coordinate, so consecutive tracker ticks glide. The first coordinate adds the marker without animation. Animation is skipped with Reduce Motion or when not in a window.
- **Waiting pulse:** while `setWaitingAtRestaurant(true)`, a tinted halo behind the restaurant marker expands (1× to 1.9×) and fades over 1.4 s, repeating. With Reduce Motion it is a static halo (1.35×, 30 % opacity). It restarts when the marker enters a window and when the app becomes active.
- **VoiceOver:** the map is one element (trait: image) labelled with `accessibilitySummary`, for example "Rider is 1.2 km from your home, on the way". Annotation views are hidden from accessibility so only the summary is read. Pan and zoom stay available to sighted users.
- **Dynamic Type:** the map doesn't scale. The text labels the frontend puts under the map wrap normally.
