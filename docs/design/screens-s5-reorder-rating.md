# Design spec: sprint 5

Same tokens and rules as [screens-s1.md](./screens-s1.md). Behaviour is defined in [sprint-5-reorder-rating.md](../contracts/sprint-5-reorder-rating.md).

## Orders tab

Two sections with `SectionHeaderView` (`DS.Font.title2`): **Active orders** (existing `OrderHistoryCell`) above
**Past orders** (`PastOrderCell`). A section with no rows has no header.

## `PastOrderCell`

```
┌────────────────────────────────────────────┐
│ ┌──────┐  KOI Express              S$ 3.81 │  body (tap → receipt)
│ │ tile │  (Waterway Point)                 │
│ └──────┘  Delivered on 25 Oct, 21:27       │
│           L-Chrysanthemum Milk Tea         │
│ ╭────────────────────────────────────────╮ │
│ │                Reorder                 │ │  PrimaryButton, full width
│ ╰────────────────────────────────────────╯ │
├────────────────────────────────────────────┤  hairline, DS.Color.separator
│ Tap to rate          ☆   ☆   ☆   ☆   ☆     │  footer
│ by 30 Oct 2026                             │
└────────────────────────────────────────────┘
```

- **Card:** `CardTableViewCell` (surface, `DS.Radius.card`, soft shadow). The cell doesn't highlight as a whole.
- **Body:** 64 pt `SymbolTileView`; name `headline`, 2 lines, truncating tail; total `headline`, right-aligned,
  never compressed; date `footnote` secondary; items `callout` secondary, 2 lines. Insets `DS.Spacing.l`. The body
  dims to 50 % while pressed.
- **Reorder:** `PrimaryButton` ("Reorder"), `DS.Spacing.l` below the body, full card width minus insets.
- **Footer:** title `subheadline` semibold secondary, subtitle `subheadline` secondary; stars on the right.
- **Stars (`StarRatingView`):** 5 × `star` / `star.fill` at 24 pt in `DS.Color.brand`; each button is at least
  44 × 44 pt, no gap.

| State | Title | Subtitle | Stars |
|---|---|---|---|
| a. In window, unrated | Tap to rate | by 30 Oct 2026 | 5 outline, editable |
| b. In window, rated | You rated | Change by 30 Oct 2026 | *n* filled, editable |
| c. Expired, rated | You rated | — | *n* filled, read-only |
| d. Expired, unrated | — (divider and footer hidden) | | |

- **Dark mode:** all colours are DS dynamic colours; the tile lightens its tint on dark surfaces.
- **Accessibility sizes (AX1+):** the tile stacks above the text, the name stacks above the total, the stars go under
  the footer text, and the name and items wrap without a line limit.
- **VoiceOver:** three elements in order: the body (button: "<name>, Delivered on …, <items>, Total <total>"), the
  "Reorder from <name>" button, and the stars (label "Rating", value "Not rated" / "4 of 5 stars", adjustable with
  hint "Rate by 30 Oct 2026" when editable; static text when read-only).
