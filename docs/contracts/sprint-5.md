# Contract: sprint 5 (Account tab)

The ground rules, ownership and conventions in [sprint-1.md](./sprint-1.md) still apply. This contract is frozen
once the agents start. Branch `feature/s5-account`, cut from `main` (sprint 2). Sprints 3–4 live on another
branch, so don't reference `DeliveryTracker`, `OrderStatusBarHost` or any tracking code.

## Decisions

| Topic | Decision |
|---|---|
| Tab | The fourth tab, "About", becomes **"Account"** with SF Symbol `person.circle`, tag 3, in the same position |
| Architecture | Two new VIPER modules: `Features/Account` (the profile page) and `Features/AccountEdit` (the edit sheet). Same shape as `Features/OrderHistory` |
| Fields | Display name, phone, email, avatar (an emoji or none, plus a palette colour) |
| Default | No profile yet: the header shows **"Guest"**, a person symbol avatar, and an **"Add your details"** button |
| Validation | Name: 1–40 characters after trimming whitespace, required. Phone: optional; when present, 8 digits starting with 3, 6, 8 or 9 (spaces, dashes and a leading `+65`/`65` are stripped first). Email: optional; when present, it must match `^[^\s@]+@[^\s@]+\.[^\s@]{2,}$` |
| Stats | Total spent, most-ordered restaurant, "Ordering since" (date of the first order). With no history, show "No orders yet" instead |
| Address | Display only: **"Home · Ngee Ann Polytechnic"** |
| About | The "About Dabao" row pushes the existing `AboutViewController`. `Credits.swift` is **not** touched (it's the Day 9 exercise) |
| Edit UX | The right bar button "Edit" (and the header's "Add your details") presents the edit module in a `UINavigationController` as a sheet (`.pageSheet`, `.large()` detent). "Cancel" sits on the left and "Save" on the right. Save is disabled while anything is invalid, and inline error text shows under each field |
| Persistence | `AppState` schema **2** adds `profile: UserProfile?`. Synthesised `Codable` decodes a missing key as `nil`, so v1 files load without being quarantined. `-dabaoReset` deletes the profile along with everything else |
| Fixtures | New `profile-sample`: the `history-mixed` orders plus a sample profile. `empty` also clears the profile. The other fixtures leave the profile alone |

## Backend (`Dabao/Models/**`, `Dabao/Services/**`)

### `Models/UserProfile.swift`

```swift
/// The avatar colour. Raw values match `DS.AvatarPalette.names` exactly.
nonisolated enum AvatarColor: String, Codable, CaseIterable, Sendable {
    case pink, orange, green, blue, purple, teal
}

nonisolated struct UserProfile: Codable, Hashable, Sendable {
    var name: String            // trimmed, 1...40 characters
    var phone: String           // "" or exactly 8 digits, stored without +65
    var email: String           // "" or valid, trimmed, stored lowercased
    var avatarEmoji: String?    // nil means use the initials
    var avatarColor: AvatarColor

    /// Up to 2 uppercase letters: the first letter of the first two words ("aisha tan" -> "AT", "Bob" -> "B").
    var initials: String { get }
}
```

### `Models/AppState.swift`

- `currentSchemaVersion = 2`.
- Add `var profile: UserProfile? = nil` as the **last** stored property. Don't write a custom `init(from:)`. Keep the memberwise initialiser working: `AppState(schemaVersion:cart:history:)` must still compile.
- `.empty` has `profile: nil`.

### `Services/ProfileValidator.swift`

```swift
nonisolated enum ProfileValidator {
    enum FieldError: Equatable, Sendable { case nameEmpty, nameTooLong, phoneInvalid, emailInvalid }

    static func validateName(_ raw: String) -> FieldError?    // trims; "" -> .nameEmpty; > 40 -> .nameTooLong
    static func normalisedPhone(_ raw: String) -> String      // strips spaces and "-"; then drops a leading "+65", or a leading "65" when the string is 10 digits long
    static func validatePhone(_ raw: String) -> FieldError?   // "" -> nil; otherwise normalised ~ ^[3689]\d{7}$
    static func validateEmail(_ raw: String) -> FieldError?   // trimmed "" -> nil; otherwise the regex above
    static func formattedPhone(_ digits: String) -> String    // "91234567" -> "+65 9123 4567"; "" -> ""
    static func message(for error: FieldError) -> String
    // .nameEmpty "Enter your name" · .nameTooLong "Keep it to 40 characters" ·
    // .phoneInvalid "Enter an 8-digit Singapore number" · .emailInvalid "Enter a valid email"
}
```

### `Services/ProfileStore.swift`

```swift
@MainActor
final class ProfileStore {
    static let shared = ProfileStore()
    static let didChangeNotification = Notification.Name("ProfileStoreDidChange")

    private(set) var profile: UserProfile?

    /// Saves an edit: trims name and email, lowercases email, normalises phone,
    /// then posts didChangeNotification and calls PersistenceController.shared.scheduleSave().
    func update(_ profile: UserProfile)

    /// Restore from disk or a fixture. Posts didChangeNotification. Doesn't save.
    func replace(_ profile: UserProfile?)
}
```

### `Services/AccountStats.swift`

```swift
nonisolated struct AccountStats: Equatable, Sendable {
    let orderCount: Int
    let totalSpent: Decimal                    // Σ order.total
    let favouriteRestaurantName: String?       // nil when there are no orders
    let favouriteRestaurantOrderCount: Int     // 0 when there are no orders
    let firstOrderDate: Date?                  // the oldest placedAt

    static func make(from orders: [PastOrder]) -> AccountStats
}
```

- **Favourite:** group by `restaurantID` and count orders, not items. The highest count wins. On a tie, the group with the most recent `placedAt` wins. The name comes from that group's most recent order.

### Wiring

- `PersistenceController.currentState()` includes `profile: ProfileStore.shared.profile`.
- `AppBootstrap` calls `ProfileStore.shared.replace(state.profile)` right after restoring history, so before fixtures are applied.
- `Fixtures.names` gains `"profile-sample"`.
  - `profile-sample` installs exactly the `history-mixed` orders and sets `UserProfile(name: "Aisha Tan", phone: "91234567", email: "aisha@example.com", avatarEmoji: "🍜", avatarColor: .teal)`. Set it via `ProfileStore.shared.replace(_:)` **before** the save.
  - `empty` also calls `replace(nil)`.
  - Refactor `history-mixed` into a helper so both fixtures share the same orders.

## Designer (`Dabao/DesignSystem/**`, `docs/design/**`)

These are plain values only. Don't reference `UserProfile`, `AvatarColor` or any model type.

```swift
extension DS {
    enum AvatarPalette {
        static let names: [String]                     // ["pink", "orange", "green", "blue", "purple", "teal"]
        static func color(named: String) -> UIColor    // dynamic light/dark; unknown names -> DS.Color.brand ("pink")
    }
}

final class AvatarView: UIView {
    enum Size { case small /* 44 pt */, large /* 88 pt */ }
    enum Content: Equatable { case initials(String), emoji(String), symbol(String) }
    init(size: Size)
    func configure(content: Content, tint: UIColor)
    // Circle filled with tint. Initials: white, rounded bold. Emoji: centred on a 20%-opacity tint circle.
    // Symbol: white SF Symbol. Fixed size, so it doesn't grow with Dynamic Type.
    // isAccessibilityElement = false (the header supplies the label).
}

struct ProfileHeaderModel: Equatable {
    let avatar: AvatarView.Content
    let tint: UIColor
    let title: String               // "Aisha Tan" or "Guest"
    let subtitle: String?           // "+65 9123 4567 · aisha@example.com"; nil hides it
    let showsAddDetailsButton: Bool
}
final class ProfileHeaderView: UIView {
    var onAddDetails: (() -> Void)?
    func configure(_ model: ProfileHeaderModel)
    // Centred column: large avatar, title (DS.Font.title2), subtitle (subheadline, textSecondary, wraps),
    // then a PrimaryButton "Add your details" when the model asks for it.
    // The title and subtitle form one VoiceOver element. Self-sizing; set it as the table header after layout.
}

struct StatItem: Hashable { let value: String; let label: String; let symbolName: String }
final class StatsRowView: UIView {
    func configure(_ items: [StatItem])
    // Equal-width tiles on DS.Color.surfaceElevated with radius small: a brand-tinted symbol, the value
    // (headline, wraps up to 2 lines) and the label (caption, textSecondary).
    // Switches to a vertical stack at accessibility sizes. Each tile is one VoiceOver element: "<label>, <value>".
}

final class FormFieldView: UIView {
    init(label: String, placeholder: String,
         keyboardType: UIKeyboardType = .default,
         textContentType: UITextContentType? = nil,
         autocapitalization: UITextAutocapitalizationType = .sentences)
    let textField: UITextField
    var text: String { get set }
    var onTextChange: ((String) -> Void)?
    func setError(_ message: String?)    // nil hides it; shown in DS.Color.danger under the field and announced to VoiceOver
}
```

- Write `docs/design/screens-s5.md`: the Account and Edit layouts in light, dark and AX5, VoiceOver labels, and the palette with contrast notes. White initials must reach ≥ 4.5:1 on every palette colour in both modes.

## Frontend (`Dabao/App/**`, `Dabao/Features/**` except Splash, `DabaoTests/**`)

### `Features/Account` (VIPER)

- `AccountRouter.createModule(profiles: ProfileStore = .shared, history: HistoryStore = .shared) -> UIViewController`.
- `AccountRouterProtocol`: `showEdit()`, which presents the AccountEdit sheet, and `showAbout()`, which pushes `AboutViewController()`.
- The interactor observes `ProfileStore.didChangeNotification` and `HistoryStore.didChangeNotification`. It reports `(UserProfile?, AccountStats)` to the presenter.
- **View:** a `UITableView`, `.insetGrouped`, background `DS.Color.background`. Title "Account", with large titles. The right bar button is "Edit".
  - **Table header:** `ProfileHeaderView`.
    - With a profile: the avatar is the emoji if set, otherwise the initials. The tint is `DS.AvatarPalette.color(named: avatarColor.rawValue)`. The subtitle joins the non-empty values of `formattedPhone(phone)` and `email` with `" · "`. No button.
    - Guest: `.symbol("person.fill")`, tint `"pink"`, title "Guest", subtitle "Add your details so riders can reach you", and the button is shown.
  - **Section "Your orders":** one cell holding a `StatsRowView` with three tiles:
    1. `PriceFormatter.string(from: totalSpent)`, label "Total spent", symbol `creditcard`.
    2. The favourite restaurant's name, label "Most ordered · N order(s)", symbol `heart`.
    3. `firstOrderDate` formatted `Date.FormatStyle().day().month(.abbreviated).year()` (for example "23 Oct 2026"), label "Ordering since", symbol `calendar`.

    With no orders, show a plain cell instead: "No orders yet" / "Your stats will show up after your first order." (secondary text).
  - **Section "Delivery address":** one cell with symbol `mappin.and.ellipse` (brand tint), text "Home", secondary text "Ngee Ann Polytechnic". Not selectable.
  - **Section "More":** "About Dabao", symbol `info.circle`, disclosure indicator. Tapping it calls `showAbout()`.
- All colours come from `DS.Color`, and every label has `adjustsFontForContentSizeCategory = true`.

### `Features/AccountEdit` (VIPER)

- `AccountEditRouter.createModule(profiles: ProfileStore = .shared) -> UIViewController` returns the **navigation controller** that wraps the edit view.
- **View:** a scroll view with a vertical stack:
  1. A live preview `AvatarView(.large)`.
  2. "Emoji": a horizontal row of choices `["None", "🍜", "🍛", "🍗", "🥟", "🧋", "🌶️", "🍰"]`. "None" means initials. The selected choice gets a brand ring, and each choice is ≥ 44 pt.
  3. "Colour": swatches for `DS.AvatarPalette.names`, with the selected one checked. VoiceOver labels use capitalised names ("Teal"). Each swatch is ≥ 44 pt.
  4. `FormFieldView`s:
     - Name: `.name`, `.words`.
     - Phone: placeholder "9123 4567", `.phonePad`, `.telephoneNumber`.
     - Email: `.emailAddress`, `.emailAddress`, `.none`.

  Fields are prefilled from the current profile. A guest gets an empty name, colour `pink` and no emoji.
- The title is "Edit profile" for an existing profile and "Your details" for a guest.
- **Errors** show for a field once it's non-empty and invalid. For the name, they also show once the user has edited it and left it empty.
- **Save** is enabled only when all three validators return nil. Tapping it calls `ProfileStore.shared.update` with the normalised phone, then dismisses.
- **Cancel** dismisses without saving. `isModalInPresentation = true` once anything has changed, so a swipe can't silently discard the edits.
- The keyboard must not cover the focused field (`keyboardLayoutGuide`).

### App

- `MainTabBarController`: replace the About tab with `UINavigationController(rootViewController: AccountRouter.createModule())`, `UITabBarItem(title: "Account", image: UIImage(systemName: "person.circle"), tag: 3)`.
- `AboutViewController` stays as it is. You may set `navigationItem.largeTitleDisplayMode = .never` on it when it's pushed.

## Test cases (TC-S5)

Launch: `-dabaoSkipSplash -dabaoNoDelay [-dabaoReset] [-dabaoFixture <name>]`. The Account tab is at x ≈ 0.81.

| # | Steps | Expected |
|---|---|---|
| 1 | `-dabaoReset -dabaoFixture empty`, open Account | Tab label is "Account". The page shows "Guest", "Add your details", "No orders yet", "Home", "Ngee Ann Polytechnic" and "About Dabao" |
| 2 | Tap "Add your details", type name "Sean Yeo", phone "8123 4567", email "sean@example.com", pick 🍛 and blue, then Save | The header shows "Sean Yeo" and "+65 8123 4567 · sean@example.com". `state.json` has `schemaVersion` 2 and `profile.phone` "81234567" |
| 3 | Edit, set phone to "1234", then email to "x@y" | The errors appear and Save is disabled. Cancel leaves the profile unchanged |
| 4 | Relaunch without reset | The profile is still shown |
| 5 | `-dabaoFixture profile-sample` | "Aisha Tan", "+65 9123 4567 · aisha@example.com". Total spent = Σ of the 4 `history-mixed` totals. Most ordered = the laksa stall (tie at 1, most recent), "1 order". Ordering since = 4 days ago |
| 6 | Write a v1 `state.json` (no `profile` key, `schemaVersion` 1) and relaunch | The cart and history are intact, the page shows Guest, and there's no `state.corrupt-*.json` |
| 7 | Tap "About Dabao" | The About screen shows the blurb and "YJ Soon (trainer)". Back returns to Account |
| 8 | Dark mode and AX5 on Account and Edit | No clipped text. The stats stack vertically. Edit fields stay reachable |
| 9 | Clean `build` plus `build-for-testing` | Green. The brand grep is clean. No `print(` or `TEMP-DEBUG` in `Dabao/`. No `UIColor(red:` or `.systemPink` in `Features`/`App` |
