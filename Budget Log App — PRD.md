# Budget Log App — PRD

Oct 27, 2026 · @crystal

## Overview

A native iOS app that logs every Apple Pay tap automatically, with no manual entry. A Shortcuts "Transaction" automation passes each Wallet payment to the app, which saves it silently and auto-categorizes it by merchant.

**Problem:** budget trackers fail because manual entry is tedious, so logs go stale within weeks.

**Goals**

- Every Apple Pay tap is logged with zero user action after one-time setup
- Any entry can be recategorized in under 3 taps
- Spending is visible as both a list and charts
- Data syncs across the user's devices and exports to a spreadsheet

**Non-goals (v1)**

- Budgets, spending limits or alerts
- Bank account linking or reading transaction history from banks
- Notes, tags or receipt photos on entries
- Android, web or App Store release

## Users and user stories

The primary user is the developer herself; a few friends get it later through TestFlight. Every user is assumed to use Apple Pay for most in-person spending.

- As a user, when I tap my phone to pay, the transaction is logged without me opening the app or seeing a notification.
- As a user, I can add a cash, online or e-transfer purchase manually in a few seconds.
- As a user, transactions from known merchants get a category automatically.
- As a user, I can change any entry's category, and optionally make that the rule for that merchant going forward.
- As a user, I can see all my transactions in one list, newest first.
- As a user, I can see charts of where my money goes by category and over time.
- As a user, my log is the same on my iPhone and iPad.
- As a user, I can export everything to a CSV and open it in a spreadsheet.

## Features

### F1. Automatic logging from Apple Pay

- The app exposes an App Intent, `LogTransactionIntent`, with parameters: amount (decimal), merchant (string), card name (string, optional).
- The user creates a personal Shortcuts automation: trigger = Transaction (any card), action = the app's "Log Transaction" intent, set to Run Immediately with notifications off.
- The intent runs without opening the app (`openAppWhenRun = false`), applies merchant rules, saves the entry and returns.
- No notification or UI is shown after a tap.
- An in-app Setup screen explains the automation in steps and confirms when the first auto-logged entry arrives.

### F2. Manual add

- A "+" button on the Log screen opens a sheet: amount, merchant, category (prefilled from rules), date (defaults to now), payment method (default "Manual").
- Saving takes one tap; amount is the only required field besides merchant.

### F3. Categories and merchant rules

- Starter categories: Food & Drink, Groceries, Transit, Shopping, Entertainment, Bills, Health, Other.
- Starter rules ship for common merchants, e.g. Tim Hortons, Starbucks → Food & Drink; Presto, Uber → Transit; Loblaws, No Frills → Groceries.
- Matching is case-insensitive "merchant contains keyword"; first match by rule priority wins; no match → Other.
- Editing an entry's category offers "Always use this for \<merchant>", which creates or updates a rule.
- A Categories screen lets the user add, rename, recolor or delete categories and edit rules. Deleting a category moves its entries to Other.

### F4. Log screen

- A single list, newest first. Each row shows merchant, category (color dot), amount and date.
- Tap a row to edit any field or delete it. Swipe to delete.
- Simple search by merchant.

### F5. Insights screen

Built with Swift Charts, with a time range picker (this week, this month, last 3 months, this year):

- Spending by category: bar or donut chart
- Spending over time: line or bar chart by day or week
- Top merchants: ranked bar chart
- A total for the selected range

### F6. CSV export

- Settings → Export opens the share sheet with a CSV: date, merchant, amount, currency, category, source, card.
- Respects the current date range or exports all (user picks).

### F7. iCloud sync

- SwiftData backed by CloudKit (private database) so entries, categories and rules sync across the user's devices.
- Works offline; syncs when online.

## Data model

Three SwiftData models. Because CloudKit sync is planned, every property has a default or is optional, no `@Attribute(.unique)` is used, and all relationships are optional.

**Transaction**

| Field | Type | Notes |
| --- | --- | --- |
| id | UUID | default `UUID()` |
| amount | Decimal | positive = spend |
| currency | String | default "CAD" |
| merchant | String | raw name from Wallet or user |
| date | Date | default now |
| source | String enum | "applePay" or "manual" |
| cardName | String? | from Wallet, nil for manual |
| category | Category? | relationship; nil shown as Other |
| categoryWasEdited | Bool | true once user overrides |

**Category**

| Field | Type | Notes |
| --- | --- | --- |
| id | UUID |  |
| name | String |  |
| colorHex | String | for chart and row dot |
| sortOrder | Int |  |
| isDefault | Bool | starter categories |
| transactions | \[Transaction\]? | inverse relationship |

**MerchantRule**

| Field | Type | Notes |
| --- | --- | --- |
| id | UUID |  |
| keyword | String | matched case-insensitively with contains |
| category | Category? |  |
| priority | Int | lower wins |
| isUserCreated | Bool | false for starter rules |

Starter categories and rules are seeded on first launch only, guarded by a flag so iCloud sync doesn't create duplicates on a second device.

## Technical architecture

Stack: Swift, SwiftUI, SwiftData, App Intents, Swift Charts, CloudKit. Minimum iOS 17 (the Shortcuts Transaction trigger and SwiftData both need it). No third-party dependencies, no backend.

**Auto-log flow**

1. User taps a card in Wallet.
2. Shortcuts Transaction automation fires and passes amount, merchant and card.
3. `LogTransactionIntent.perform()` runs in the background.
4. `CategoryResolver` matches the merchant against `MerchantRule`s.
5. A `Transaction` is inserted into the shared `ModelContainer` and saved.
6. CloudKit syncs it; the Log and Insights views update through `@Query`.

**Structure**

- `Models/` — Transaction, Category, MerchantRule
- `Intents/` — LogTransactionIntent, AppShortcutsProvider
- `Services/` — CategoryResolver, Seeder, CSVExporter
- `Views/` — LogView, TransactionEditView, AddTransactionView, InsightsView, CategoriesView, SettingsView, SetupGuideView
- One shared `ModelContainer` used by both the app and the intent, so intent writes show up in the UI immediately.
- `CategoryResolver` is a plain struct with no UI dependency so it can be unit tested.

## Build phases

Build in this order. Each phase ends in a runnable app. iCloud and TestFlight come last because they need the paid Apple Developer account.

1. **Core log**: models, seeding, Log screen, manual add, edit and delete.
   - [ ] App launches with starter categories seeded exactly once
   - [ ] Manually added entries appear newest first and persist across relaunch
   - [ ] Entries can be edited and deleted
2. **Auto-logging**: LogTransactionIntent, AppShortcutsProvider, Setup guide.
   - [ ] "Log Transaction" appears as an action in the Shortcuts app
   - [ ] A real Apple Pay tap creates an entry with no notification and without opening the app
   - [ ] Running the intent manually from Shortcuts with test values also works
3. **Categories and rules**: CategoryResolver, starter rules, edit category, "always use this", Categories screen.
   - [ ] Known merchants are categorized automatically; unknown go to Other
   - [ ] "Always use this" makes future entries from that merchant use the new category
   - [ ] Unit tests cover resolver matching, priority and no-match cases
4. **Insights**: Swift Charts screen with range picker.
   - [ ] By-category, over-time and top-merchant charts render with real data
   - [ ] Empty state shows when there's no data in the range
5. **CSV export**
   - [ ] Exported CSV opens correctly in Numbers and Excel with the listed columns
6. **iCloud sync and TestFlight**
   - [ ] An entry added on one device appears on a second signed-in device
   - [ ] Seeding does not duplicate categories on the second device
   - [ ] Build is distributed to at least one friend through TestFlight

## Constraints, risks and open questions

**Constraints**

- Only Apple Pay taps are captured. Physical card swipes, online purchases and e-transfers need manual entry.
- Each user must set up the Shortcuts automation themselves; apps can't create it for them.
- A free Apple account allows on-device testing only, with builds expiring after 7 days. CloudKit and TestFlight need the paid Apple Developer Program (US$99/year).

**Risks**

- The amount from the Transaction trigger may arrive as a formatted string (e.g. "$4.25"), not a number. Parse defensively and log raw input during Phase 2 testing.
- Merchant names from Wallet can be messy (e.g. "TIM HORTONS #1234"). Contains-matching on keywords handles most cases.
- Refunds and returns may come through as transactions. v1 logs them as entered; the user can delete.
- FinanceKit could read transactions directly, but it needs a special Apple entitlement and mainly supports Apple Card, so it's out of scope.

**Open questions**

- [ ] App name
- [ ] Should refunds show as negative amounts?
- [ ] Multi-currency support, or CAD only for v1?
