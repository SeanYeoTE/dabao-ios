# Design spec: sprint 3

Same tokens and rules as [screens-s1.md](./screens-s1.md). Behaviour is defined in [sprint-3.md](../contracts/sprint-3.md).

## `OrderStatusBar` (floating "order on the way" pill)

```
┌──────────────────────────────────────────┐
│ [tile]  On the way · 12 min      +1   ›  │   headline, textPrimary
│         Ah Seng Chicken Rice             │   subheadline, textSecondary
│▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│   3 pt brand progress line
└──────────────────────────────────────────┘
```

- Surface: `surfaceElevated`, radius `DS.Radius.card`, soft shadow (stronger in dark mode) and a 0.5 pt `separator` border. ≥ 56 pt tall, grows with text, never clips.
- Parts: 40 pt `SymbolTileView` (restaurant symbol), title (stage + ETA), subtitle (restaurant), `+N` badge (brand text on a brand 14 % fill, hidden when 0), chevron, progress line along the bottom (clipped by the pill's corners; flips in RTL).
- **Delivered:** tile becomes a success-coloured checkmark, the line is full and success-coloured, no chevron. Title "Delivered".
- **Accessibility sizes (AX1+):** the row stacks vertically, the tile and chevron are hidden, and `+N` moves into the subtitle ("Ah Seng · +1"). The title and subtitle wrap.
- **VoiceOver:** one button. Label "Order from Ah Seng, on the way, about 12 minutes, 1 more order" (delivered: "Order from Ah Seng, delivered"). Hint "Shows order tracking".
- **Motion:** `configure(_, animated: true)` animates the progress line (0.4 s) and cross-dissolves text and state changes (0.25 s). With Reduce Motion, or when not in a window, everything is applied instantly.
- Usage: pin it with 16 pt side insets; the host owns visibility and placement. Pass `animated: false` for the first configuration.

## Placement and stacking

| Situation | Rule |
|---|---|
| Tabs | The bar's bottom sits `DS.Spacing.s` above the tab bar |
| Pushed Menu (tab bar hidden) | The bar sits `DS.Spacing.s` above the bottom safe area |
| With `StickyCartBar` | They stack: order bar at the very bottom, cart bar directly above it |
| Order tracking of the order shown | The bar is hidden |
| No active orders | The bar is hidden |

The host adds `barHeight + DS.Spacing.s` to each navigation controller's bottom safe-area inset, so cart bars and scroll content move up and nothing is covered.

## Order tracking screen (`hidesBottomBarWhenPushed`, title "Your order")

Scrolling grouped layout on `DS.Color.background`, 16 pt side margins, 24 pt between blocks:

1. **Header card:** 56 pt `SymbolTileView`, restaurant name (`title2`), then a large ETA line ("Arriving in 12 min" in `title`, brand colour; "Arrived" in success colour when delivered) and "Estimated 6:42 PM" (`subheadline`, `textSecondary`). Stacks vertically at AX sizes.
2. **`DeliveryTimelineView`** on a white surface card with 16 pt padding.
3. **Items:** `ReceiptLineCell` rows, then `PriceSummaryView` as the footer.

## `DeliveryTimelineView`

- Four rows (Confirmed, Preparing, On the way, Delivered). Each has a 24 pt dot and a 2 pt connector to the next dot; rows are ≥ 52 pt and the label wraps at AX sizes.
- **Done:** filled brand dot with a white check, brand connector. **Current:** brand ring with an inner dot, bold label, and a pulsing halo (1.4 s, static with Reduce Motion). **Future:** grey ring, secondary label, grey connector.
- **VoiceOver:** each step is one element: "Preparing, current step", "Confirmed, completed", "On the way, upcoming".
- Changes cross-dissolve per row when `animated` and Reduce Motion is off. Changing the stage titles rebuilds the rows.
