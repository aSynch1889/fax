# Data Models & Schema Reference

All data models in FaxFlow are value types conforming to Codable, Identifiable, and Hashable.

## 1. FaxDocument
Represents a multi-page draft or ready-to-send fax package.
- id: UUID
- title: String
- createdAt: Date
- updatedAt: Date
- pages: [FaxPage]
- coverPage: CoverPageData
- totalPagesCount: Computed integer

## 2. FaxPage
Represents an individual document page within a FaxDocument.
- id: UUID
- imageFileName: String (Stored in Application Support/FaxFlowData/PageImages/)
- rotationAngle: Double (0, 90, 180, 270 degrees)
- filter: FilterType (.original, .blackAndWhite, .grayscale, .enhancedDoc)
- signatures: [SignaturePlacement]

## 3. SignaturePlacement
Defines coordinates and dimensions of an e-signature stamped onto a page.
- id: UUID
- relativeX: CGFloat (Normalized 0.0 to 1.0)
- relativeY: CGFloat (Normalized 0.0 to 1.0)
- relativeWidth: CGFloat (Normalized 0.0 to 1.0)
- signatureImageData: Data (PNG bytes)

## 4. CoverPageData & Templates
- template: CoverPageTemplate (.professional, .modern, .minimal, .urgent)
- senderName, senderPhone, recipientName, recipientCompany, subject, notes

## 5. FaxRecipient
- id: UUID
- name: String
- organization: String
- countryCode: String (ISO Alpha-2)
- dialCode: String (e.g. +1, +49)
- faxNumber: String
- isFavorite: Bool

## 6. FaxTransmissionRecord
- id: UUID
- confirmationCode: String (e.g. FAX-884920)
- recipient: FaxRecipient
- sentDate, completedDate: Date
- pageCount: Int
- status: TransmissionStatus (.queued, .dialing, .transmitting, .delivered, .failed)
- creditsUsed: Int
- transmissionDurationSeconds: Int
- receiptPDFFileName: String?
- subject: String
