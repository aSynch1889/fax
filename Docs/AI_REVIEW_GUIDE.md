# AI Review & Developer Maintenance Guide (Codex / Grok)

This document provides explicit guidelines, architectural context, and code invariants for AI coding assistants (Codex, Grok, Claude) working on or reviewing the FaxFlow codebase.

## 1. Codebase Invariants
1. XcodeGen as Single Source of Truth: Never manually edit .xcodeproj. Always edit project.yml and run xcodegen generate.
2. Strict Multi-Language: Never hardcode visible strings. Always add to Resources/Localizable.xcstrings across all 5 languages (en, zh-Hans, zh-Hant, ja, ko).
3. StoreKit 2 Native: Use StoreKit 2 APIs (Product, StoreKit.Transaction).
4. Sandboxed File Storage: Always store user documents in Application Support/FaxFlowData/ via StorageManager.shared.
5. Dark & Light Mode: Always use semantic colors and glassCard() modifiers.

## 2. Module Quick Reference
- App Entry: Sources/App/FaxApp.swift
- Main Tabs: Sources/App/MainTabView.swift
- Send Flow: Sources/Features/SendFax/SendFaxView.swift
- Scanner: Sources/Services/DocumentScannerService/DocumentScannerCoordinator.swift
- Document Editor: Sources/Features/DocumentEditor/DocumentEditorView.swift
- Signatures: Sources/Features/Signature/SignaturePadView.swift
- Cover Pages: Sources/Features/CoverPage/CoverPageEditorView.swift
- PDF & Receipts: Sources/Core/Utilities/PDFGenerator.swift
- StoreKit 2: Sources/Services/StoreKit/StoreManager.swift
- Transmission State Machine: Sources/Services/FaxTransmissionService/FaxTransmissionService.swift
- Local Storage: Sources/Core/Storage/StorageManager.swift
