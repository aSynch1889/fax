# Detailed Module Inventory & Interface Contracts

| Module Identifier | Source Path | Key Responsibilities | Dependencies | Status |
| :--- | :--- | :--- | :--- | :--- |
| App.Lifecycle | Sources/App/FaxApp.swift, Sources/App/AppState.swift | App boot, environment injection, tab routing | SwiftUI, Combine | Completed |
| App.Navigation | Sources/App/MainTabView.swift | 4-Tab root layout, badge counts, accent styling | SwiftUI | Completed |
| Core.Theme | Sources/Core/Theme/AppTheme.swift | Semantic colors, view modifiers, glassmorphism | SwiftUI, UIKit | Completed |
| Core.Models | Sources/Core/Models/FaxModels.swift | Data structures, Enums, Codable definitions | Foundation, CoreGraphics | Completed |
| Core.Storage | Sources/Core/Storage/StorageManager.swift | Sandboxed JSON and JPEG persistence, screenshot mocks | Foundation, UIKit | Completed |
| Core.Country | Sources/Core/Utilities/CountryManager.swift | 90+ countries dataset, dial prefixes, ISO matching | Foundation | Completed |
| Core.Filter | Sources/Core/Utilities/ImageFilterUtility.swift | Hardware CoreImage Noir, Contrast, Unsharp filters | CoreImage, UIKit | Completed |
| Core.PDF | Sources/Core/Utilities/PDFGenerator.swift | US-Letter multi-page PDF & official receipt builder | PDFKit, CoreGraphics | Completed |
| Core.Phone | Sources/Core/Utilities/PhoneFormatter.swift | Telephone string sanitization and mask formatting | Foundation | Completed |
| Service.StoreKit | Sources/Services/StoreKit/StoreManager.swift | StoreKit 2 product loader, purchases, transaction listener | StoreKit, Combine | Completed |
| Service.Transmission | Sources/Services/FaxTransmissionService/FaxTransmissionService.swift | Multi-step transmission state machine & credit deductions | Foundation, UIKit | Completed |
| Service.Scanner | Sources/Services/DocumentScannerService/DocumentScannerCoordinator.swift | UIViewControllerRepresentable for VNDocumentCameraViewController | VisionKit, SwiftUI | Completed |
| Feature.SendFax | Sources/Features/SendFax/SendFaxView.swift | Main fax composer, credit requirement counter, action button | SwiftUI, PhotosUI | Completed |
| Feature.CountryPicker | Sources/Features/SendFax/CountryPickerView.swift | Searchable modal sheet for international dialing codes | SwiftUI | Completed |
| Feature.Contacts | Sources/Features/Contacts/ContactsListView.swift | Address book list, add contact sheet, favorite filter | SwiftUI | Completed |
| Feature.DocEditor | Sources/Features/DocumentEditor/DocumentEditorView.swift | Multi-page editor, page rotation, filter picker, signatures | SwiftUI, CoreImage | Completed |
| Feature.CoverPage | Sources/Features/CoverPage/CoverPageEditorView.swift | 4-template cover editor (Professional, Modern, Minimal, Urgent) | SwiftUI | Completed |
| Feature.Signature | Sources/Features/Signature/SignaturePadView.swift | PencilKit canvas for finger / stylus signatures, library | PencilKit, SwiftUI | Completed |
| Feature.History | Sources/Features/History/HistoryListView.swift | Sent & Outbox segments, transmission log detail, receipt preview | QuickLook, SwiftUI | Completed |
| Feature.Paywall | Sources/Features/Paywall/PaywallView.swift | StoreKit 2 subscriptions & credit packs purchase sheet | StoreKit, SwiftUI | Completed |
| Feature.Settings | Sources/Features/Settings/SettingsView.swift | Balance display, Face ID toggle, terms & privacy links | LocalAuthentication, SwiftUI | Completed |
| Feature.Settings.Language | Sources/Features/Settings/LanguageSettingsView.swift | In-app language picker with instant switching | LanguageManager, SwiftUI | Completed |
| Feature.Settings.Appearance | Sources/Features/Settings/AppearanceSettingsView.swift | In-app light / dark / system appearance picker with instant switching | AppearanceManager, SwiftUI | Completed |
| Resources.Localization | Resources/Localizable.xcstrings | 5 languages: en, zh-Hans, zh-Hant, ja, ko | String Catalog | Completed |
| Resources.Assets | Resources/Assets.xcassets | AppIcon, AccentColor, Color Sets | Asset Catalog | Completed |
