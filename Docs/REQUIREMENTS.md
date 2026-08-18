# Product Requirements Document (PRD)

## 1. Executive Summary
- App Name: FaxFlow: Fax from iPhone & iPad
- Bundle Identifier: com.evolly.faxflow
- Target OS: iOS 17.0+ / iPadOS 17.0+
- Reference Application: FAX from iPhone & iPad App by BPMobile (App ID: 1135811739)
- Category: Business (Primary), Utilities (Secondary)

## 2. Functional Requirements Matrix

### 2.1 Document Scanning & Ingestion (REQ-SCAN)
- REQ-SCAN-01: Must integrate Apple VisionKit (VNDocumentCameraViewController) for automatic boundary detection, perspective deskewing, and flash control.
- REQ-SCAN-02: Must support importing single or multiple images directly from the user Photo Library via PhotosUI (PhotosPicker).
- REQ-SCAN-03: Must support importing arbitrary PDF files from the iOS Files app / iCloud Drive via UIDocumentPickerViewController.
- REQ-SCAN-04: Scanned pages must be stored in the app sandboxed Application Support/FaxFlowData/PageImages directory in high-quality JPEG format.

### 2.2 Document Editing & Post-Processing (REQ-EDIT)
- REQ-EDIT-01: Multi-page carousel view supporting swipe navigation, page reordering, and individual page deletion.
- REQ-EDIT-02: 90-degree clockwise page rotation with geometry persistence.
- REQ-EDIT-03: CoreImage-based hardware filter pipeline (Original, B&W Fax, Grayscale, Enhanced Doc).

### 2.3 E-Signature & Document Markup (REQ-SIGN)
- REQ-SIGN-01: Responsive canvas utilizing Apple PencilKit (PKCanvasView) supporting finger, stylus, and Apple Pencil pressure sensitivity.
- REQ-SIGN-02: Capability to clear canvas, undo strokes, and save signature vector/raster representations to a local signature library.
- REQ-SIGN-03: Placement of signatures onto any selected document page with interactive positioning and scaling.

### 2.4 Cover Page Generation (REQ-COVER)
- REQ-COVER-01: Support 4 distinct cover page templates (Professional, Modern, Minimalist, Urgent Priority).
- REQ-COVER-02: Dynamic parameter insertion: Sender Name, Sender Phone/Return Fax, Recipient Name, Company, Subject, Remarks/Notes, Page Count, and Current Date.
- REQ-COVER-03: Cover page toggle switch (adds exactly 1 page to the PDF header and credit calculation).

### 2.5 Global International Fax Dispatcher (REQ-DISPATCH)
- REQ-DISPATCH-01: Complete pre-loaded dataset of 90+ destination countries with ISO 3166-1 alpha-2 codes, country flags (emoji), international dial prefixes (+1, +44, +81, etc.), and phone number masks.
- REQ-DISPATCH-02: Instant searchable country picker sheet.
- REQ-DISPATCH-03: Multi-stage state machine simulator for transmission lifecycle (Queued -> Dialing Line -> Handshake Verification -> Transmitting Page N of Total -> Delivered / Failed).
- REQ-DISPATCH-04: Automatic generation of official PDF Transmission Confirmation Receipts featuring confirmation codes (FAX-XXXXXX), timestamps, page counts, durations, and cryptographic validation badges.

### 2.6 Address Book & History Tracking (REQ-HIST)
- REQ-HIST-01: Local contact directory with favorite toggle, organization name, and one-tap auto-fill into the composer.
- REQ-HIST-02: Segmented History View separating Sent Faxes and Outbox / In-Progress.
- REQ-HIST-03: Integration with QuickLook (QLPreviewController) to view and export official transmission receipt certificates.

### 2.7 StoreKit 2 Monetization & Entitlements (REQ-IAP)
- REQ-IAP-01: Auto-renewable subscription tiers:
  - com.evolly.faxflow.sub.weekly: $3.99/week with 3-day free trial.
  - com.evolly.faxflow.sub.monthly: $9.99/month.
  - com.evolly.faxflow.sub.yearly: $50.99/year (Best Value).
- REQ-IAP-02: Consumable fax credit packages:
  - com.evolly.faxflow.credits.10: $4.99 (10 Pages).
  - com.evolly.faxflow.credits.50: $19.99 (50 Pages).
  - com.evolly.faxflow.credits.100: $34.99 (100 Pages).
- REQ-IAP-03: Real-time transaction listener (StoreKit.Transaction.updates), background entitlement sync (Transaction.currentEntitlements), and one-tap restore purchases (AppStore.sync()).
