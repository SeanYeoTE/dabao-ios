# Dabao

A pretend food delivery app, written in UIKit, for the NP iOS traineeship. "Dabao" is Singlish for takeaway.

We use Dabao as our "existing app": a codebase you didn't write, that you'll learn to find your way around, debug, extend and improve over the course.

## Running it

1. Open `Dabao.xcodeproj` in Xcode 27 (Xcode 26 should work too).
2. Pick an iPhone simulator at the top of the window.
3. Press `Cmd-R`.

There's no server: the 100 restaurants and their menus come from `Dabao/Resources/restaurants.json`, and your cart and past orders are saved on the device.

## Finding your way around

| Folder | What's in it |
| --- | --- |
| `Dabao/App` | Start-up code and the tab bar |
| `Dabao/Models` | Plain data: `Restaurant`, `MenuItem`, `CartLine`, `PastOrder`, `AppState` |
| `Dabao/Services` | The on-device "backend": catalogue, cart, order history, saving, recommendations, launch options |
| `Dabao/DesignSystem` | Colours, fonts, spacing and shared UI pieces (cards, chips, cart bar, quantity control) |
| `Dabao/Features/Splash` | The pink launch splash |
| `Dabao/Features/RestaurantList` | Home: search, cuisine chips, "For you" and the restaurant list. Plain MVC |
| `Dabao/Features/Menu` | A restaurant's menu. Built with **VIPER** |
| `Dabao/Features/Cart` | The cart tab and Place order. Plain MVC |
| `Dabao/Features/OrderHistory` | The Orders tab: past orders. **VIPER** |
| `Dabao/Features/Receipt` | A read-only receipt for one past order. **VIPER** |
| `Dabao/Features/OrderTracking` | Live tracking for an order that's on its way. **VIPER** |
| `Dabao/Features/About` | About screen and the list of contributors |
| `DabaoTests` | Unit tests for the Menu presenter |
| `scripts/gen_catalogue.py` | Generates the restaurant catalogue |
| `docs/` | Sprint contracts, design specs and the accessibility audit |

## What the app does

- **Home** lists 100 made-up Singapore hawker stalls and restaurants. You can search (by name, cuisine, area, tags or dish) and filter by cuisine.
- **Menu** shows a restaurant's dishes by category. A cart holds food from one restaurant at a time, so adding from a second restaurant asks before replacing the cart. Closed restaurants and sold-out dishes can't be ordered.
- **Cart** lets you change quantities, swipe to delete, add notes and see the subtotal, delivery fee and total. **Place order** saves the order to your history and empties the cart.
- **Orders** lists past orders, newest first. Tap one to see its receipt. A receipt is a snapshot, so it stays the same even if the menu changes.
- **For you** on Home suggests restaurants based on what you've ordered before.
- **Order on the way**: after you place an order, a floating bar above the tab bar shows its progress (Confirmed → Preparing → On the way → Delivered) and the minutes left. Tap it for the tracking screen, which has a map of the restaurant, the rider and your home. There's no server, so progress is worked out from the time the order was placed and the restaurant's delivery time (`Services/DeliveryTracker.swift`).

## How it works

### Saving

The cart and order history are saved together as one JSON file, `Application Support/Dabao/state.json`, with a `schemaVersion`. Saves are batched (a short debounce), written atomically on a background queue, and flushed when the app goes into the background. If the file can't be read, it's moved aside as `state.corrupt-<time>.json` rather than overwritten.

### Recommendations

"For you" is an on-device bag-of-words recommender (`Services/Recommender.swift`):

1. Each restaurant becomes a document: its name, cuisine and tags (counted twice), description, and its dishes' names and tags.
2. Words are lowercased, stripped of punctuation and stopwords, and plurals are trimmed ("noodles" → "noodle").
3. Each document becomes a TF-IDF vector. This is worked out once, off the main thread.
4. Your taste profile adds up the vectors of restaurants you ordered from, weighted by how many items you ordered, with older orders counting less (×0.8 per order).
5. Open restaurants are ranked by cosine similarity to your profile. Restaurants from your last 3 orders are halved, so it's not all repeats. Ties go to the lower restaurant id.
6. The caption explains the pick: "Because you ordered Laksa Lemak with Prawns".

With no orders yet, it falls back to popularity: rating × ln(1 + review count).

### The catalogue

`restaurants.json` is generated, not hand-written:

```bash
/usr/bin/python3 scripts/gen_catalogue.py
```

The script uses only the Python standard library and a fixed random seed, so it gives the same file every time. The first five restaurants (`r1`–`r5`) are the original ones the course exercises use.

### Delivery map

The tracking screen's map uses fixed locations, not GPS: each restaurant is placed in its area (with a small fixed offset), and orders go to a fixed address, Ngee Ann Polytechnic. The route comes from Apple Maps driving directions between those points, or a dashed curve if that isn't available. The rider waits at the restaurant while the food is prepared, then moves along the route as the order progresses (`Services/DeliveryRouteProvider.swift`, `Models/DeliveryRoute.swift`).

## Launch arguments

Handy for demos and testing. Add them in Xcode under *Product › Scheme › Edit Scheme › Run › Arguments*, or pass them to `xcrun simctl launch`:

| Argument | What it does |
| --- | --- |
| `-dabaoReset` | Deletes the saved cart and history |
| `-dabaoSkipSplash` | Skips the splash screen |
| `-dabaoNoDelay` | Skips the pretend 0.4 s network delay |
| `-dabaoOfflineMap` | Skips Apple Maps directions and draws an approximate route |
| `-dabaoFastDelivery` | Makes each delivery minute last one second, to watch an order arrive |
| `-dabaoFixture <name>` | Starts with sample data: `empty`, `cart-chicken-rice`, `history-laksa`, `history-mixed`, `order-on-the-way` or `two-active-orders` |

For example:

```bash
xcrun simctl launch booted com.tinkercademy.dabao -dabaoSkipSplash -dabaoNoDelay -dabaoFixture history-laksa
```

## Branches

| Branch | Used on | What it is |
| --- | --- | --- |
| `main` | Day 1 onwards | The app as it is |
| `bug-hunt` | Day 10 | The same app with a few bugs added, plus an `AGENTS.md` that sets up OpenCode as a tutor |
| `viper-exercise` | Day 13 | A Menu bug to fix, and a half-built Restaurant Info module to finish |
| `viper-solution` | Day 13 (afterwards) | One way to finish the VIPER exercise |
| `a11y-solution` | Day 16 (afterwards) | One way to fix the accessibility issues we find in our audit |

## Contributing

On Day 9 you'll fork this repo, add your name to `Dabao/Features/About/Credits.swift`, and open a pull request. See the course notes for the steps.
