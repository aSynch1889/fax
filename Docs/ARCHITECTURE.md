# System Architecture

## Overview
MVVM architecture with SwiftUI, Combine, and async/await Swift Concurrency.

## Subsystems
- Document Pipeline: VisionKit -> CoreImage -> PDFGenerator
- Transmission Engine: FaxTransmissionService async lifecycle + PDF confirmation receipt
- StoreKit 2 Manager: Subscriptions & Consumable Credit Packs
