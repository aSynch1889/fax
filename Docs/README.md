# FaxFlow: Fax from iPhone & iPad (iOS 17.0+)

**FaxFlow** is an enterprise-grade mobile facsimile transmission application for iPhone and iPad, replicated and engineered based on the industry-leading App Store application "FAX from iPhone & iPad App" by BPMobile (App ID: 1135811739).

It transforms iOS and iPadOS devices into a portable, high-efficiency, end-to-end encrypted document scanner and international fax machine.

## Key Highlights
- Native SwiftUI & iOS 17 Architecture: 100% built using SwiftUI, Combine, and modern Swift Concurrency (async/await, @MainActor).
- Hardware-Accelerated Document Scanner: Powered by VisionKit (VNDocumentCameraViewController) for automatic boundary detection, perspective deskewing, and shadow elimination.
- Hardware CoreImage Enhancement Filters: 4 processing modes: Original, B&W Fax (High Contrast), Grayscale, and Enhanced Document (Unsharp Masking).
- PencilKit Digital E-Signature Pad: Create legally binding vector signatures using finger or Apple Pencil, save to personal library, and drag/scale stamp onto any page.
- Cover Page Generator: 4 built-in professional cover templates (Professional, Modern, Minimalist, Urgent Priority) with automatic page count calculation and metadata rendering.
- Global Fax Dispatcher (90+ Countries): International dialer with ISO matching, automatic number formatting, real-time multi-stage transmission simulator, and official cryptographic PDF confirmation receipts.
- StoreKit 2 Monetization Suite: Auto-renewable subscriptions (Weekly with 3-day trial, Monthly, Yearly) and consumable page credit packs (10, 50, 100 credits) with auto-entitlement verification.
- Mandatory 5-Language String Catalog: Zero hardcoded strings. Full localization in English (en), Simplified Chinese (zh-Hans), Traditional Chinese (zh-Hant), Japanese (ja), and Korean (ko).
- Semantic Dark & Light Theme: Complies with Apple Human Interface Guidelines using dynamic system colors, glassmorphism cards, and contrast accessibility.
- Biometric Security: Optional Face ID / Touch ID authentication layer for confidential business faxes and address book protection.

## Quick Start & Building
1. Install XcodeGen:
   brew install xcodegen
2. Generate Xcode project:
   xcodegen generate
3. Compile for iOS Simulator:
   xcodebuild -project FaxFlow.xcodeproj -scheme FaxFlow -destination "platform=iOS Simulator,name=iPhone 17" -derivedDataPath .derivedData build
