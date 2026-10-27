# Sprint 5 QA report: Orders redesign with Reorder and inline rating

Tested on the iPhone 17 Pro QA simulator (iOS 26), launched with `-dabaoSkipSplash -dabaoNoDelay -dabaoReset`. Taps and
drags went through `serve-sim@0.1.48`. Each check was confirmed with OCR on a `simctl` screenshot and, where relevant,
`state.json` read with `jq`.

| TC | Result | Evidence |
|---|---|---|
| 1. Layout | Pass | `history-rating`: "Past orders" header, no "Active orders". Order 1: "Ah Seng Chicken Rice / $13.19 / Delivered on 26 Oct, 10:28 / 2 × Steamed Chicken Rice, 1 × Braised Egg / Reorder / Tap to rate / by 29 Oct 2026" |
| 2. Rate and persist | Pass | Star 4 → "You rated / Change by 29 Oct 2026"; `state.json` `history[0].rating` = 4; still 4 after relaunch without reset; star 2 → 2 |
| 3. Expired orders | Pass | Mala Mama (5 days ago): no footer. Order 5 (6 days, rated 3): "You rated" with no subtitle; tapping a star leaves ratings `[2,null,4,null,3]` unchanged |
| 4. Reorder, empty cart | Pass | Cart tab opens: "Steamed Chicken Rice × 2, Note: Less rice", "Braised Egg × 1", total $13.19; `state.json` cart matches |
| 5. Reorder, cart conflict | Pass | "Replace your cart? / Your cart has items from Ah Seng Chicken Rice. Start a new cart from Ah Seng Chicken Rice?" Cancel keeps quantities `[2,2]`; Replace gives `[2,1]` and opens Cart |
| 6. Blocked reorders | Pass | Green Bowl: "Green Bowl is closed / You can reorder when it opens again." Order 3: "Some items are unavailable / Sold out or no longer on the menu: Lime Juice." Cart stays `[]` |
| 7. Active orders | Pass | `order-on-the-way` + `-dabaoFastDelivery`: "Active orders / On the way • 8 min" above "Past orders"; tap → "Your order". Staying on Orders, the row moves to Past orders with "Tap to rate" on delivery |
| 8. Receipt, dark, AX5, builds, greps | Pass | Card body tap → "Receipt". Dark mode readable (brand stars and button). AX5: tile, name, total and stars stack; nothing clipped. Clean `build` and `build-for-testing` succeed; brand, `print`, `TEMP` / `UserDefaults` greps are empty |

## Bugs found and fixed during the gate

| Severity | Bug | Fix |
|---|---|---|
| P2 | A slow drag that started on a card (body, Reorder or stars) didn't scroll the list, because `UIScrollView` doesn't cancel touches in `UIControl`s by default | `66498a6`: the Orders table returns `true` from `touchesShouldCancel(in:)` |
| P3 | Stars spread wider in the read-only footer (no subtitle) than in the others | `344e6fe`: each star is exactly 44 pt wide |

## Known issues

- **P3:** "Change by 29 Oct 2026" wraps onto two lines at the default text size, because the five 44 pt stars leave about 120 pt for the text. Readable; left as is.
- In `history-rating`, the "first open restaurant with a sold-out item" is `r1`, so order 3 is from the same restaurant as order 1. The blocking path is still covered (Lime Juice is sold out).

## Notes

- XCTest not run (standing user request); `DabaoTests` compiles (`build-for-testing`).
- Sprint 5 agents had no shell or file tools in this session, so the PM wrote every role's code itself, keeping each role's commit tags and file ownership.
