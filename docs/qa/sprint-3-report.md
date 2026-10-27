# Sprint 3 QA report: floating "order on the way" bar

We tested on the booted iPhone 17 Pro simulator (iOS 26). The app was launched with `-dabaoSkipSplash -dabaoNoDelay`. Taps went through `serve-sim@0.1.48`. Each check was confirmed by running OCR (macOS Vision) on a `simctl` screenshot.

| TC | Result | Evidence |
|---|---|---|
| 1. Bar on Home | Pass | With `order-on-the-way`, "On the way · 13 min / Ah Seng Chicken Rice" shows at y≈0.85, above the tab labels at y≈0.96 |
| 2. Persists across tabs and pushes | Pass | The bar stays on the Orders tab. On restaurant pages it sits above the home indicator, with "View cart" stacked above it (checked by the frontend) |
| 3. Tap opens tracking | Pass | Shows "Your order", "Arriving in 12 min", "Estimated 10:12 AM", the 4-stage timeline, the items and the total. The bar is hidden there and comes back after Back |
| 4. Several orders | Pass | `two-active-orders` shows "Preparing · 12 min / Kopi Corner · +1" |
| 5. Live progress (`-dabaoFastDelivery`) | Pass | After Place order: the "Order placed" toast, then Confirmed · 24 → Preparing · 22…16 → On the way · 13…3 → the "…has arrived" toast and "Delivered". The bar hides after about 4 s |
| 6. Relaunch mid-delivery | Pass | After kill and relaunch, the bar comes back as "On the way · 12 min" |
| 7. Dark mode and AX5 | Pass | Home: the cart bar and order bar stack without overlapping, and the tab labels stay visible. The tracking header and timeline wrap without clipping |
| 8. Build, test target and brand | Pass | `build` and `build-for-testing` succeed. The brand grep and the hard-coded colour, `print` and debug-hook greps are all clean |

**Open issues:**
- **P3:** at AX5, the two stacked bars take up about half the screen height. Content is still reachable because the safe-area insets keep it scrollable.
