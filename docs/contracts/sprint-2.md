# Contract: sprint 2 (history and recommendations)

The APIs are defined in [sprint-1.md](./sprint-1.md). This file pins down behaviour.

## HistoryStore

- `place(cart:)` snapshots the cart:
  - restaurant id, name, cuisine, `imageName` and `colorHex`
  - each line's menu item id, name, unit price, quantity and notes
  - subtotal, delivery fee and total
- After snapshotting, `place(cart:)`:
  1. inserts the order at index 0
  2. posts `didChangeNotification`
  3. calls `cart.clear()`
  4. calls `PersistenceController.shared.scheduleSave()`
- Receipts render only from the snapshot, never from the catalogue.

## Recommender

1. **Document per restaurant.** Join these fields, each tokenised; a field's tokens are repeated to apply its weight:
   - the name
   - the cuisine, twice
   - each tag, twice
   - the description
   - every menu item's name and tags
2. **`tokenize`:**
   - lowercase, and fold diacritics
   - split on non-letters and non-digits
   - drop tokens shorter than 2 characters and stopwords (`and, the, with, of, in, a, an, set, for, to, on, our, house, special, cup, plate, bowl, side`)
   - stem plurals: `ies`→`y`; otherwise drop a trailing `s` when the word is longer than 3 letters and doesn't end in `ss`
3. **Vectors.** `tf = count / docLength`, `idf = ln((N + 1) / (df + 1)) + 1`, then L2-normalise. Store as `[String: Double]`. Build it in `Task.detached` and set `isReady` on main.
4. **Profile.** Take the history newest first, so k = 0 is the newest order. Profile = Σ vec(restaurant) × order.itemCount × 0.8^k. Skip orders whose restaurant isn't in the catalogue.
5. **Ranking.**
   - Candidates are open restaurants only.
   - score = cosine(profile, vec).
   - Restaurants that appear in the 3 newest orders get score × 0.5.
   - Sort by score descending, ties broken by restaurant id ascending (numeric-aware: `r2` < `r10`), then take `limit`.
6. **Reason.** Pick the past order line whose name tokens have the highest summed weight in the candidate's vector; ties go to the newer order. The reason is `"Because you ordered <line name>"`. If nothing overlaps, use `"Similar to <restaurantName>"` for the newest order's restaurant.
7. **Cold start (empty history or no index yet).**
   - Score = rating × ln(1 + reviewCount), open restaurants only.
   - Ties broken by id.
   - Reason `"Popular on Dabao"`.

### Worked example (`history-laksa`)

The history is 3 orders at the first `laksa` restaurant (call it L1).

1. The profile is dominated by tokens like `laksa`, `peranakan`, `coconut`, `curry` and `noodle`.
2. The other `laksa` and Peranakan restaurants score highest.
3. L1 itself is in the last 3 orders, so it's halved and must not be first.

The expected top 3 are all tagged `laksa` or have cuisine `Peranakan`. Each reason starts with `Because you ordered` and contains `Laksa`.

## UI

- **Place order** (Cart):
  - `PrimaryButton` "Place order · $total".
  - Confirmation alert ("Place order?" / "Place order" / "Cancel"), then `HistoryStore.shared.place`.
  - After placing: show the toast "Order placed", and update the cart badge.
- **Orders tab** (VIPER module `Features/OrderHistory`): `OrderHistoryCell` list, newest first, diffable by order `UUID`.
  - Date text uses the relative date + time style ("Today, 6:42 PM").
  - Empty state: "No orders yet" / "Your past orders will show up here."
  - Tap pushes the Receipt.
- **Receipt** (VIPER module `Features/Receipt`, read-only):
  - `ReceiptHeaderView`, then `ReceiptLineCell` rows, then a `PriceSummaryView` footer.
  - No reorder button.
- **Home "For you"**: a section above the restaurants with a `SectionHeaderView` "For you" and a `ForYouCarouselView` showing the top 10.
  - Hidden while searching or filtering.
  - Refreshes on `HistoryStore.didChangeNotification` and `Recommender.didUpdateNotification`.
  - Tapping opens the Menu.

## Test cases (TC-S2)

As listed in the plan, plus: no `UIColor(red:` or `.systemPink` / `.systemGreen` literals in `Dabao/Features` or `Dabao/App` (use `DS.Color`).
