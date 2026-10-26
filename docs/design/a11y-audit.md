# Accessibility audit (sprint 2)

Scope: `Dabao/DesignSystem/**` and `SplashViewController`. Method: a code audit of every component, plus screenshots on
the iPhone 17 simulator (`90A40A3B`) of Home at the default size, and at AX5 in dark mode, until the frontend started using
that simulator. Not checked on a device: VoiceOver speech, Bold Text and Switch Control. Re-check those by hand.

## Fixed in the design system

| Area | Issue | Fix |
|---|---|---|
| Dark mode, contrast | "Closed" badge text was below 4.5:1 (light red on grey, and light red on dark grey). | `DS.Color.danger` light is now `#B3261E`. The badge sits on `DS.Color.background`. |
| Non-text contrast | The unselected chip border (`separator`) was about 1.2:1 against the page. | The border is `textTertiary` at 50 %. |
| AX5 | `StickyCartBar` took about half the screen at AX5: badge, title and total each had a row. | At accessibility sizes the badge is hidden and the count moves into the title ("View cart (3)"). The total stays on its own row. |
| AX5 | The count badge could be narrower than it is tall, which drew an odd shape. | The badge is at least as wide as it is tall. |
| Dark mode | Data-driven tile colours (`Restaurant.colorHex`) were too dark on dark cards. | `SymbolTileView` lightens the symbol colour by 40 % in dark mode and uses a 20 % tint background. |
| VoiceOver, layout | `SectionHeaderView` had no height outside a table (the frontend puts "For you" in a stack), so the title was invisible. | It reports an intrinsic height. This doesn't change its behaviour in a table. |
| VoiceOver | A selected chip didn't say how to clear it. | The selected chip has the hint "Double tap to clear this filter". |

## Checked and fine

- **AX5 and Dynamic Type:**
  - Labels use scaled fonts, `adjustsFontForContentSizeCategory` and `numberOfLines = 0`.
  - Rows switch to a vertical layout from AX1 (`AdaptiveStackView`).
  - Tiles and buttons are the only fixed sizes, and they are decorative or minimums.
  - Attributed meta text and the carousel height are recomputed when the text size changes.
  - `EmptyStateView` scrolls.
- **Bold Text:** all text uses system fonts at regular weight or heavier, so the system's bold adjustment applies. No custom fonts.
- **Reduce Motion:** the splash finishes immediately with no animation. `Toast` only fades (no slide). The carousel and chip bar apply updates without animation.
- **VoiceOver:**
  - Cards, bars and receipt rows are single elements with full labels.
  - `QuantityControl` is an adjustable element (swipe up or down).
  - Section titles and the receipt header have the header trait.
  - `Toast` posts an announcement.
- **Tap targets:**
  - `QuantityControl` buttons are 44×44.
  - Chips are drawn about 36 pt tall but have a 44 pt hit area.
  - `PrimaryButton` is at least 50 pt, `StickyCartBar` at least 56 pt, and the card rows are taller than 44 pt.
- **Dark mode:** every colour is dynamic. White text on brand is 5.6:1 in light mode. In dark mode the brand fill `#FF3D87` gives white text 3.4:1 (see below).

## Known limitation (contract)

- In dark mode, white text on the brand fill `#FF3D87` (`PrimaryButton`, `StickyCartBar`, selected chip) is 3.4:1. That is enough for large or bold text but not for normal text under WCAG AA. The token values are frozen in the contract. If the PM wants AA, use a darker fill such as `#E0246F` for filled controls in dark mode.

## For the frontend

- Unselected tab icons render black or dark in dark mode on iOS 26 (system tab bar styling). Nothing to do unless it shows up in QA.
- `MenuItemCell`: sold-out dishes use `alpha = 0.5` on text. That is below 4.5:1 by design, and "Sold out" is also spoken. Consider `textSecondary` instead of alpha, so the text stays readable.
- `CartLineCell`: the notes button limits the title to two lines. At AX5 a long note is truncated. Show the full note, or add the note to the row's accessibility value.
- After `ForYouCarouselView.setItems` the carousel's height can change (text size, reasons wrapping). Keep calling `sizeTableHeader()` after `refreshForYou()` and on `viewDidLayoutSubviews`.
- Show `Toast` in a view that is above the tab bar and the `StickyCartBar`. It sits 64 pt above the bottom safe area.
