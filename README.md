# Budget Log (working name)

An iOS app that logs every Apple Pay tap automatically. See `Budget Log App — PRD.md` for the full spec.

**Status:** Phase 1 (core log) is written but has not been compiled yet. This Mac has no Xcode, and its Command Line Tools have a compiler/SDK version mismatch.

## Run it

1. Install **Xcode** from the Mac App Store (needed for iOS builds, and it also fixes the broken Command Line Tools).
2. Point the command line at it: `sudo xcode-select -s /Applications/Xcode.app`
3. Generate the project: `brew install xcodegen && xcodegen generate`
4. Open `BudgetLog.xcodeproj`. Under *Signing & Capabilities*, pick your team (a free Apple ID works for on-device testing; builds expire after 7 days).
5. Run on your iPhone or a simulator. Run tests with ⌘U.

`BudgetLog.xcodeproj` is generated from `project.yml`, so edit `project.yml` rather than the project, and run `xcodegen generate` again after adding files.

## Layout

| Path | What |
| --- | --- |
| `BudgetLog/Models/` | SwiftData models: `Entry` (a transaction), `Category`, `MerchantRule` |
| `BudgetLog/Services/` | `CategoryResolver` (merchant → category), `AmountInput` (parses "$4.25" etc.), `StarterData`, `Seeder` |
| `BudgetLog/Views/` | `LogView` (list, search, swipe to delete), `EntryFormView` (add / edit / delete) |
| `BudgetLogTests/` | Unit tests for the resolver and amount parsing |

The transaction model is called `Entry` because `Transaction` clashes with SwiftUI's own `Transaction` type.

## Decisions baked in

- CAD only.
- Refunds are stored as negative amounts (Refund toggle in the add/edit form) and reduce totals.
- Starter categories have fixed ids, and a merge pass runs at launch, so iCloud sync (Phase 6) can't leave duplicate categories.

## Phase 1 checklist (from the PRD)

- [ ] App launches with starter categories seeded exactly once
- [ ] Manually added entries appear newest first and persist across relaunch
- [ ] Entries can be edited and deleted
