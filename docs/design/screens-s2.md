# Design spec: sprint 2

Same tokens and rules as [screens-s1.md](./screens-s1.md).

## Screens

- **Home "For you":** `SectionHeaderView` "For you" above a `ForYouCarouselView` (top 10). Hidden while searching or filtering.
- **Orders tab:** `OrderHistoryCell` cards, newest first. Empty state: "No orders yet" / "Your past orders will show up here."
- **Receipt:** `ReceiptHeaderView`, `ReceiptLineCell` rows on a white surface, then a `PriceSummaryView` footer. Read-only, no reorder button.
- **Cart:** a `PrimaryButton` "Place order · $total" below the summary. Placing shows the toast "Order placed".

## Components

| Component | Notes |
|---|---|
| `ForYouCarouselView` | 270 pt cards in a horizontal strip. The height is the tallest card, so it can be a table header (it has an intrinsic height). At AX sizes cards fill the width. A diffable data source keyed by `card.id`: changed items are reconfigured, not reloaded. Selection sends the restaurant id. |
| `OrderHistoryCell` | Card with a 56 pt tile, name, relative date, items summary, total and a chevron. Stacks vertically at AX sizes. |
| `ReceiptHeaderView` | Centred 72 pt tile, name and date. One VoiceOver header element. |
| `ReceiptLineCell` | Quantity (brand, bold), name, optional notes, price. Spoken as "2 times Chicken Rice, Note: …, $7.00". |

## Accessibility

- Cards and rows are one VoiceOver element with a full label (the carousel card adds the reason).
- All layouts wrap and stack at AX5; the carousel re-measures when the text size changes.
- Diffable updates are not animated when Reduce Motion is on.
