# System Architecture & Technical Design

## 1. High-Level Architecture Pattern
FaxFlow is architected around the MVVM (Model-View-ViewModel) and Service-Oriented Architecture (SOA) paradigm, implemented in pure Swift 5.9 / iOS 17 SwiftUI.

UI Presentation Layer (SwiftUI Views)
    |
Services & Coordinators Layer (StoreManager, FaxTransmissionService, DocumentScannerCoordinator, PDFGenerator)
    |
Core Layer & Sandboxed Persistence (StorageManager, CountryManager, ImageFilterUtility, PhoneFormatter)

## 2. Key Subsystems
1. Document & PDF Generation Pipeline:
   - VisionKit captures document pages.
   - ImageFilterUtility applies CoreImage hardware filters.
   - PDFGenerator renders cover pages, filtered images, and vector signatures into standard US-Letter PDF bytes.
2. StoreKit 2 Monetization Engine:
   - StoreManager handles StoreKit 2 Product loading, transaction updates, and cryptographic entitlement verification.
3. Sandboxed Storage:
   - Sandboxed inside Application Support/FaxFlowData/ with JSON indices and image assets.
