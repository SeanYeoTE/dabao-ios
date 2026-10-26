# Design spec: sprint 1

Look: a pink brand, white rounded cards on a light grey background, pill chips, a sticky pink cart bar and a pink
selected tab. Everything adapts to dark mode. All code is in `Dabao/DesignSystem`.

## Tokens (`DS`)

| Token | Light | Dark |
|---|---|---|
| `Color.brand` | `#D70F64` | `#FF3D87` |
| `Color.background` | `#F2F2F4` | black |
| `Color.surface` | white | `#1C1C1E` |
| `Color.textPrimary / Secondary / Tertiary` | `#1F1F24 / #5F6168 / #6E7078` | `#F5F5F7 / #AEAEB4 / #8E8E93` |

- Radius: card 14, small 8, button 24. Spacing: 2, 4, 8, 12, 16, 24, 32. Minimum tap target: 44.
- Fonts are `UIFontMetrics`-scaled (rounded design for titles). Labels set `adjustsFontForContentSizeCategory` and `numberOfLines = 0`.
- `DS.applyGlobalAppearance()` styles the navigation bar, the tab bar (brand selected tint), `UISwitch` and alerts. `AccentColor` is brand pink with a dark variant.
- Screens never use colour literals or `.systemPink`; they use `DS.Color` (and `UIColor(hex:)` for restaurant colours).

## Screens

- **Splash:** brand background, white "dabao" wordmark and bag symbol. About 0.8 s. With Reduce Motion it ends immediately, with no animation.
- **Home:** large title, search, `ChipBar` ("All" + cuisines), `RestaurantCardCell` list on the grey background, `StickyCartBar` above the tab bar when the cart has items, `EmptyStateView` when nothing matches.
- **Menu:** header (name, cuisine, area, rating, ETA, fee, description), `SectionHeaderView` per category, add buttons with 44 pt targets.
- **Cart:** rows with name, notes preview, price and `QuantityControl`; `PriceSummaryView` footer; `EmptyStateView` when empty.

## Components

| Component | Notes |
|---|---|
| `RestaurantCardCell` | Card inset 16 pt. 72 pt tinted tile, name, subtitle, "★ rating (reviews) · ETA · fee", up to 3 tags. Closed: "Closed" badge and dimmed tile. |
| `ChipBar` | Pills, 44 pt hit area. Selected = brand fill, white text. Tapping the selected chip sends `nil`. |
| `StickyCartBar` | Brand pill, at least 56 pt high: count badge, title, total. |
| `QuantityControl` | 44×44 buttons. One adjustable VoiceOver element ("Quantity", value n). |
| `PriceSummaryView` | Draws its own white card; pin it with 16 pt side margins. |
| `EmptyStateView` | Scrolls at AX sizes. The optional action is a `PrimaryButton`. |
| `PrimaryButton` | Brand capsule, at least 50 pt high, wraps its title. |
| `Toast` | Bottom pill, 2 s, announces to VoiceOver. Only fades when Reduce Motion is on. |

## Accessibility rules

- Rows, bars and chips are single VoiceOver elements with a full spoken label (for example "Laksa House, Peranakan · Katong, Rated 4.6, 1.2k reviews, 25 min, $2.99 delivery").
- Horizontal rows become vertical at accessibility text sizes (`AdaptiveStackView`). No fixed heights that clip text.
- Text uses `textSecondary` or darker for body copy (at least 4.5:1 contrast). Colour never carries meaning alone ("Closed" is also text).
- Every tap target is at least 44 pt. Animations are skipped or reduced with Reduce Motion.
