# Milestone Progress & Verification Status

## 1. Quality & Compliance Checklist
- XcodeGen Generation: Valid project created with project.yml (PASS)
- Simulator Compilation: iOS 17.0+ Simulator Build (PASS - BUILD SUCCEEDED)
- StoreKit 2 Integration: Subscriptions & Consumable Credits (PASS)
- 5-Language Localization: en, zh-Hans, zh-Hant, ja, ko (PASS - 100% Covered)
- VisionKit Scanner: Hardware Document Scanner (PASS)
- PDFKit Compiler: Multi-page PDF + Receipt Engine (PASS)
- PencilKit Signature: Hand-drawn E-Signatures (PASS)
- Dark & Light Mode: Semantic Colors + In-App Appearance Switcher (PASS)
- Privacy Web Deployment: Public repo aSynch1889/faxflow-privacy + GitHub Pages (PASS) https://asynch1889.github.io/faxflow-privacy/
- Screenshot Mock Mode: Automated Screenshot Data Injection (PASS)

## 2. Compilation Record
- Target: FaxFlow (iOS 17.0)
- Architecture: arm64-apple-ios17.0-simulator
- Status: BUILD SUCCEEDED with 0 errors

## 3. Localization Hardening Pass (2026-08-18)
Scope: eliminated all hardcoded user-visible strings found by a full-source audit.

- Files fixed (10): ContactsListView, CoverPageEditorView, DocumentEditorView,
  HistoryListView, PaywallView, SendFaxView, SettingsView, CountryPickerView,
  FaxTransmissionService, PDFGenerator
- Catalog: `Resources/Localizable.xcstrings` grown 74 → 171 keys; every entry
  translated in en / zh-Hans / zh-Hant / ja / ko; format placeholders (%@ / %d)
  verified consistent across languages
- Patterns applied:
  - SwiftUI literals → snake_case keys (auto LocalizedStringKey lookup)
  - Interpolated strings → `String(format: NSLocalizedString(...))`
  - Non-View layers (service step text, PDF drawing) → `NSLocalizedString`
  - `DetailRow.label` changed `String` → `LocalizedStringKey`
  - Paywall price/subtext computed as localized format strings at call site
- Verified non-localizable residuals (intentional): placeholder phone
  `+1 (800) 555-FAX1`, version `1.0.0 (Build 1)`, country name data,
  page indexes, `•` separators
- Rebuild: `xcodegen generate` + iPhone 17 Simulator build → BUILD SUCCEEDED

## 4. In-App Language Switching (2026-08-19)
Scope: settings entry → language picker second-level page with instant switching.

- New `LanguageManager` (`Sources/App/LanguageManager.swift`): `AppLanguage`
  enum (system / en / zh-Hans / zh-Hant / ja / ko), preference persisted in
  UserDefaults (`AppLanguagePreference`) and mirrored to `AppleLanguages`
- `L10n.s()` dynamic-bundle helper replaces all 61 `NSLocalizedString` calls,
  so non-View strings (PDF engine, service step text, alerts) switch instantly
  without an app restart
- Root-level `.environment(\.locale, ...)` in `FaxApp` makes every
  `Text("key")` re-resolve on selection change
- New `LanguageSettingsView`: checkmark picker, options rendered in their own
  language, immediate apply, footer note
- `SettingsView` migrated `NavigationView` → `NavigationStack`, added
  通用/General section with Language row showing current selection
- Tab bar hidden on pushed second-level pages via
  `.toolbar(.hidden, for: .tabBar)` (LanguageSettingsView, ContactsListView)
- Catalog: +4 keys (`settings_general`, `settings_language`,
  `language_follow_system`, `language_change_note`) → 181 total
- Rebuild: `xcodegen generate` + iPhone 17 Simulator build → BUILD SUCCEEDED

## 5. In-App Appearance Switching (2026-08-19)
Scope: settings entry → appearance picker second-level page (mirror of the
language-switching pattern).

- New `AppearanceManager` (`Sources/App/AppearanceManager.swift`):
  `AppAppearance` enum (system / light / dark), preference persisted in
  UserDefaults (`AppAppearancePreference`)
- Root-level `.preferredColorScheme(...)` in `FaxApp` applies the choice to
  the whole view tree (nil = follow the system); all screens already use
  semantic colors, so both schemes remain readable
- New `AppearanceSettingsView`: checkmark picker, immediate apply, footer
  note, tab bar hidden via `.toolbar(.hidden, for: .tabBar)`
- `SettingsView` General section gains an Appearance row (above Language)
  showing the current selection
- Catalog: +5 keys (`settings_appearance`, `appearance_follow_system`,
  `appearance_light`, `appearance_dark`, `appearance_change_note`) → 186 total
- Rebuild: `xcodegen generate` + iPhone 17 Simulator build → BUILD SUCCEEDED

### Known follow-ups (P2)
- Country names in CountryManager are English-only data (~200 entries);
  localization would require a per-language country name table
- Paywall prices are placeholder strings; production should render
  `Product.displayPrice` from StoreKit 2
- Demo/mock records in StorageManager contain English sample data
