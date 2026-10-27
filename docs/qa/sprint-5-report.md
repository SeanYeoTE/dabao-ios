# Sprint 5 QA report: Account tab

Tested on a dedicated iPhone 17 Pro simulator ("Dabao QA S5", iOS 26), so the shared QA device stayed free for other work. The build tested is `feature/s5-account`, rebased onto `main` after PR #2 (sprints 3–4). Taps and typing went through `serve-sim@0.1.48`. Each check was confirmed with OCR on a `simctl` screenshot, and layouts were also inspected visually.

| TC | Result | Evidence |
|---|---|---|
| 1. Fresh guest | Pass | `-dabaoReset -dabaoFixture empty`: the tab says "Account" and the page shows "Guest", "Add your details so riders can reach you", the "Add your details" button, "No orders yet", "Home / Ngee Ann Polytechnic" and "About Dabao" |
| 2. Add details | Pass | Typed "Sean Yeo", "8123 4567" and "sean@example.com", then picked 🍛 and blue and saved. The header shows "Sean Yeo / +65 8123 4567 · sean@example.com". `state.json` has `schemaVersion` 2 and `profile.phone` "81234567". The preview showed "SY" before the emoji was picked |
| 3. Validation and Cancel | Pass | A phone of "8123 45671234" shows "Enter an 8-digit Singapore number". The email "sean@example.comx@y" shows "Enter a valid email". Save was greyed out. Cancel left the profile and `state.json` unchanged |
| 4. Relaunch | Pass | Relaunching without reset still shows "Sean Yeo" and the contact line |
| 5. `profile-sample` stats | Pass | "Aisha Tan / +65 9123 4567 · aisha@example.com". Total "$48.79" = 13.78 + 7.49 + 11.13 + 16.39. Most ordered is "Ah Liang Peranakan Laksa · 1 order" (a four-way tie, won by the most recent order). "Ordering since Oct 23, 2026" is 4 days ago |
| 6. v1 migration | Pass | A `state.json` rewritten with `schemaVersion` 1 and no `profile` key loads with its 2 cart lines intact. The page shows Guest and no `state.corrupt-*.json` is created |
| 7. About row | Pass | It pushes About: the blurb, "Version 1.0." and "Made by / YJ Soon (trainer)". Back returns to Account |
| 8. Dark mode and AX5 | Pass | In dark mode, the palette swatches, ring and checkmark are all visible. At AX5 the header wraps, the stat tiles stack, the edit fields scroll, and "None" stays readable after a fix |
| 9. Build and greps | Pass | Clean `build` and `build-for-testing` succeed. The brand, `print`, `TEMP-DEBUG`, `CLLocationManager` and colour-literal greps are clean |
| Extra: floating order bar | Pass | `order-on-the-way`: the "On the way · 13 min" bar shows on Account, and "About Dabao" scrolls clear of it. The stats include the active order (Ah Seng Chicken Rice, 2 orders, $56.28) |

## Bugs found and fixed during the gate

- **P2:** a long restaurant name in the "Most ordered" tile was clipped mid-word ("Ah Liang Peranaka"). Values now get 3 lines and can shrink to 75 %.
- **P3:** at AX5, the stacked stat tiles kept equal heights, which left a large gap. Stacked tiles now size to their content.
- **P2:** at AX5, the "None" emoji choice became "…". Its label now shrinks to fit the fixed 48 pt circle.

## Known issues (P3, not fixed)

- At AX5, a long email address wraps mid-word in the header ("aisha@example.co / m"). Addresses have no spaces to break on.
- In dark mode, an emoji avatar sits on a very dark tint (20 % of the colour over black). It's readable, but low-key.
- "Ordering since" follows the device locale, so it reads "Oct 23, 2026" on en-US rather than "23 Oct 2026".
- Save stays enabled on an unchanged, valid profile. Saving is harmless, but it isn't disabled.

XCTest was not run, at the user's request. `DabaoTests` compiles.
- PR: https://github.com/SeanYeoTE/dabao-ios/pull/3
