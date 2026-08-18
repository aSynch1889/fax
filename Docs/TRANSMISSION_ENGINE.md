# Fax Transmission Engine & Gateway Integration Guide

## 1. State Machine Lifecycle
1. Validation: Verify destination number & required credits
2. Deduct Credits: Decrement balance or verify active subscription
3. Queued: Create transmission record
4. Dialing: Establish carrier line connection
5. Transmitting: Stream page chunks (1..N) with progress updates
6. Verification: Remote handshake confirmation
7. Delivered: Generate official PDF transmission confirmation receipt

## 2. Confirmation Receipt Structure
- Header: Official Confirmation Seal & Code (FAX-XXXXXX)
- Recipient & Destination Number (+Country Code)
- Timestamp, Duration (seconds), Pages Transmitted
- Consumed credits & Verification status
- Exportable via QuickLook (AirPrint, Email, Save to Files)
