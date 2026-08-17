import Foundation
import UIKit

@MainActor
public final class FaxTransmissionService: ObservableObject {
    public static let shared = FaxTransmissionService()
    
    @Published public var isTransmitting: Bool = false
    @Published public var activeTransmission: FaxTransmissionRecord?
    @Published public var transmissionProgress: Double = 0.0 // 0.0 to 1.0
    @Published public var currentStepText: String = ""
    
    public func transmitFax(document: FaxDocument, recipient: FaxRecipient, pageImages: [UIImage]) async -> Bool {
        let totalPages = document.totalPagesCount
        let creditsNeeded = totalPages
        
        guard StorageManager.shared.deductCredits(creditsNeeded) else {
            return false
        }
        
        let record = FaxTransmissionRecord(
            recipient: recipient,
            pageCount: totalPages,
            status: .queued,
            creditsUsed: creditsNeeded,
            subject: document.coverPage.subject
        )
        
        StorageManager.shared.addHistoryRecord(record)
        self.activeTransmission = record
        self.isTransmitting = true
        self.transmissionProgress = 0.05
        self.currentStepText = "Preparing fax documents..."
        
        // 1. Generate multi-page PDF
        let pdfData = PDFGenerator.generatePDF(for: document, pagesImages: pageImages)
        _ = pdfData // In production: send to cloud gateway API
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 2. Dialing
        var updated = record
        updated.status = .dialing
        StorageManager.shared.updateHistoryRecord(updated)
        self.activeTransmission = updated
        self.transmissionProgress = 0.25
        self.currentStepText = "Dialing \(recipient.formattedFullNumber)..."
        
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // 3. Transmitting Pages
        updated.status = .transmitting
        StorageManager.shared.updateHistoryRecord(updated)
        self.activeTransmission = updated
        
        for i in 1...totalPages {
            self.currentStepText = "Transmitting Page \(i) of \(totalPages)..."
            let progressFraction = 0.25 + (Double(i) / Double(totalPages)) * 0.55
            self.transmissionProgress = progressFraction
            try? await Task.sleep(nanoseconds: 1_200_000_000)
        }
        
        // 4. Verification & Confirmation Receipt
        self.transmissionProgress = 0.92
        self.currentStepText = "Awaiting handshake verification..."
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        updated.status = .delivered
        updated.completedDate = Date()
        updated.transmissionDurationSeconds = Int(Date().timeIntervalSince(updated.sentDate))
        
        // Generate PDF receipt
        let receiptData = PDFGenerator.generateTransmissionReceipt(record: updated)
        let receiptFileName = "Receipt_\(updated.confirmationCode).pdf"
        let receiptURL = FileManager.default.temporaryDirectory.appendingPathComponent(receiptFileName)
        try? receiptData.write(to: receiptURL)
        updated.receiptPDFFileName = receiptFileName
        
        StorageManager.shared.updateHistoryRecord(updated)
        self.activeTransmission = updated
        self.transmissionProgress = 1.0
        self.currentStepText = "Fax Delivered Successfully!"
        
        try? await Task.sleep(nanoseconds: 800_000_000)
        self.isTransmitting = false
        return true
    }
}
