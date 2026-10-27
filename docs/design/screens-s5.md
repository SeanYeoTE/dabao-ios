# Design spec: sprint 5 (Account)

Same tokens and rules as [screens-s1.md](./screens-s1.md). The contract is [sprint-5.md](../contracts/sprint-5.md).

## Screens

- **Account tab.** "Account" with `person.circle`, in the fourth position, which used to be About.
  - Large title "Account" and an "Edit" bar button.
  - **Header:** `ProfileHeaderView`, centred: 88 pt avatar, name (`title2`), and contact line (`subheadline`, secondary).
    - A guest gets a pink circle with `person.fill`, "Guest", "Add your details so riders can reach you" and a `PrimaryButton` "Add your details".
  - **"Your orders":** a `StatsRowView` with three tiles (Total spent, Most ordered, Ordering since) on `surfaceElevated`, inside an insetGrouped cell. With no orders, a plain cell says "No orders yet" plus a secondary hint.
  - **"Delivery address":** brand `mappin.and.ellipse`, "Home" / "Ngee Ann Polytechnic". Display only.
  - **"More":** "About Dabao" with `info.circle` and a disclosure chevron. It pushes the existing About screen.
- **Edit sheet.** A page sheet with a large detent. "Cancel" on the left, "Save" on the right, and Save is disabled while invalid. From top to bottom:
  - the live 88 pt avatar preview
  - "Emoji": a row of 44 pt choices, with "None" meaning initials; the selected choice gets a 2 pt brand ring
  - "Colour": 44 pt palette swatches, with a white checkmark on the selected one
  - `FormFieldView`s for Name, Phone and Email

  Errors appear in `danger` under the field, and the field border turns `danger` too.

## Components

| Component | Notes |
|---|---|
| `AvatarView` | 44 or 88 pt fixed circle. Initials are white rounded bold at 38 % of the diameter. An emoji sits at 50 % on a 20 % tint. A symbol is white at half size. Hidden from VoiceOver. |
| `ProfileHeaderView` | Self-sizing column. The name and contact line are a single VoiceOver header element ("Aisha Tan, +65 9123 4567 · aisha@example.com"). |
| `StatsRowView` | Equal-width tiles: a brand symbol, the value (`headline`, 2 lines) and the label (`caption`). Each tile is one element, "Total spent, $45.20". Vertical at AX sizes. |
| `FormFieldView` | Footnote label, a 44 pt+ bordered field on `surface`, and a danger error line. The error is posted as an announcement when it first appears and is added to the field's accessibility value. |

## Avatar palette

White text contrast (WCAG relative luminance). Every pair passes 4.5:1. Dark-mode pink is `#C2185B` rather than the brighter dark brand `#FF3D87`, which only reaches 3.35:1 against white.

| Name | Light | Ratio | Dark | Ratio |
|---|---|---|---|---|
| pink | `#D70F64` | 5.07 | `#C2185B` | 5.87 |
| orange | `#B34700` | 5.50 | `#A84300` | 6.06 |
| green | `#1E7F4F` | 5.00 | `#1B7347` | 5.85 |
| blue | `#1F5FBF` | 6.09 | `#2A62C9` | 5.69 |
| purple | `#7B3FBF` | 6.35 | `#7E47C9` | 5.78 |
| teal | `#00786F` | 5.36 | `#007A70` | 5.23 |

## Accessibility

- Every label uses `adjustsFontForContentSizeCategory`. The stats tiles stack at AX sizes, and the edit form scrolls and keeps the focused field above the keyboard.
- Emoji and colour choices are buttons with labels ("Noodles", "Teal") and the selected trait.
