# Sprint 4 QA report: delivery map

Tested on the booted iPhone 17 Pro simulator (iOS 26). Taps went through `serve-sim@0.1.48`. Each check was confirmed by running OCR on a `simctl` screenshot.

| TC | Result | Evidence |
|---|---|---|
| 1. Map and rider distance | Pass | `order-on-the-way` at normal speed: "Rider is 10.3 → 9.8 km away" and "Arriving in 13 → 12 min" over about 20 s. With `-dabaoFastDelivery`: 7.0 → 2.9 → 2.1 km → 410 m |
| 2. Waiting at restaurant | Pass | `two-active-orders`, Kopi Corner: "Arriving in 12 min / Waiting at restaurant". The map renders ("Maps Legal" is visible) |
| 3. Offline fallback | Pass | `-dabaoOfflineMap`: "Rider is 7.4 km away" on the curved fallback route, with no hang or crash |
| 4. Delivered | Pass | "Arrived / Delivered at 10:22 AM / Delivered to Home". The screen stays put for at least 18 s after delivery |
| 5. No GPS | Pass | No `CLLocationManager` or `NSLocation*` keys in the source or `Info.plist`, and no permission prompt |
| 6. Dark mode and AX5 | Pass | The map shows road labels (PIE, CTE, AYE). The header wraps ("Ah Seng / Chicken Rice", "Arriving in / …") |
| 7. Build and brand | Pass | Clean `build-for-testing` succeeds. The brand, colour, `print` and debug-hook greps are clean |

## Triage

- **Closed (not reproducible):** an early fast-delivery run jumped back to Home after delivery. A careful re-run held the tracking screen for 18 s or more after "Delivered", and the code has no close path for a delivered order (`journey` is never nil). The earlier run most likely picked up a stray serve-sim gesture right after the helper restarted.

## Notes

- The online route length (about 10 km by road) is longer than the offline curve (about 7 km), as expected.
- Online routing depends on Apple Maps being reachable. Offline, the dashed fallback route is used.
