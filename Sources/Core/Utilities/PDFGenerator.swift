import UIKit
import PDFKit

public final class PDFGenerator {
    public static let standardPageSize = CGSize(width: 612, height: 792) // US Letter: 8.5 x 11 inches at 72 dpi
    
    public static func generatePDF(for document: FaxDocument, pagesImages: [UIImage]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "FaxFlow iOS",
            kCGPDFContextAuthor: document.coverPage.senderName.isEmpty ? "FaxFlow User" : document.coverPage.senderName,
            kCGPDFContextTitle: document.title
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: standardPageSize), format: format)
        
        return renderer.pdfData { context in
            // 1. Draw Cover Page if enabled
            if document.coverPage.isEnabled {
                context.beginPage()
                drawCoverPage(data: document.coverPage, totalDocPages: document.pages.count + 1, in: context.cgContext)
            }
            
            // 2. Draw Each Document Page
            for (index, page) in document.pages.enumerated() {
                guard index < pagesImages.count else { continue }
                context.beginPage()
                let rawImage = pagesImages[index]
                let filteredImage = ImageFilterUtility.apply(filter: page.filter, to: rawImage)
                let rotatedImage = rotate(image: filteredImage, byDegrees: page.rotationAngle)
                
                drawImageFit(image: rotatedImage, in: context.cgContext)
                
                // Draw signatures
                for sig in page.signatures {
                    if let sigImage = UIImage(data: sig.signatureImageData) {
                        drawSignature(sigImage, placement: sig, in: context.cgContext)
                    }
                }
            }
        }
    }
    
    public static func generateTransmissionReceipt(record: FaxTransmissionRecord) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: standardPageSize))
        return renderer.pdfData { context in
            context.beginPage()
            let cg = context.cgContext
            
            // Header
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            "FAX TRANSMISSION RECEIPT".draw(at: CGPoint(x: 40, y: 50), withAttributes: titleAttributes)
            "Official Delivery Confirmation & Log".draw(at: CGPoint(x: 40, y: 80), withAttributes: subtitleAttributes)
            
            // Divider
            cg.setStrokeColor(UIColor.separator.cgColor)
            cg.setLineWidth(1)
            cg.move(to: CGPoint(x: 40, y: 110))
            cg.addLine(to: CGPoint(x: standardPageSize.width - 40, y: 110))
            cg.strokePath()
            
            // Details
            let fieldFont: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .medium), .foregroundColor: UIColor.secondaryLabel]
            let valFont: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .bold), .foregroundColor: UIColor.label]
            
            var y: CGFloat = 135
            let items: [(String, String)] = [
                ("Confirmation Code:", record.confirmationCode),
                ("Recipient:", record.recipient.name.isEmpty ? "Direct Fax Line" : record.recipient.name),
                ("Destination Number:", record.recipient.formattedFullNumber),
                ("Country:", record.recipient.countryCode),
                ("Transmission Status:", record.status == .delivered ? "DELIVERED (SUCCESS)" : "FAILED"),
                ("Pages Sent:", "\(record.pageCount) Pages"),
                ("Sent Timestamp:", DateFormatter.localizedString(from: record.sentDate, dateStyle: .medium, timeStyle: .medium)),
                ("Duration:", "\(record.transmissionDurationSeconds) seconds"),
                ("Subject:", record.subject.isEmpty ? "N/A" : record.subject)
            ]
            
            for (key, val) in items {
                key.draw(at: CGPoint(x: 40, y: y), withAttributes: fieldFont)
                val.draw(at: CGPoint(x: 200, y: y), withAttributes: valFont)
                y += 32
            }
            
            // Status Seal
            let sealRect = CGRect(x: standardPageSize.width - 180, y: 140, width: 140, height: 60)
            cg.setFillColor(record.status == .delivered ? UIColor.systemGreen.withAlphaComponent(0.15).cgColor : UIColor.systemRed.withAlphaComponent(0.15).cgColor)
            cg.fill(sealRect)
            cg.setStrokeColor(record.status == .delivered ? UIColor.systemGreen.cgColor : UIColor.systemRed.cgColor)
            cg.setLineWidth(2)
            cg.stroke(sealRect)
            
            let statusText = record.status == .delivered ? "VERIFIED" : "ERROR"
            let statusAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .black),
                .foregroundColor: record.status == .delivered ? UIColor.systemGreen : UIColor.systemRed
            ]
            let textSize = statusText.size(withAttributes: statusAttr)
            statusText.draw(at: CGPoint(x: sealRect.midX - textSize.width / 2, y: sealRect.midY - textSize.height / 2), withAttributes: statusAttr)
            
            // Footer notice
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            "Generated cryptographically by FaxFlow Secure Transmission Gateway.".draw(at: CGPoint(x: 40, y: standardPageSize.height - 60), withAttributes: footerAttr)
        }
    }
    
    private static func drawCoverPage(data: CoverPageData, totalDocPages: Int, in context: CGContext) {
        let margin: CGFloat = 40
        let contentWidth = standardPageSize.width - margin * 2
        
        let titleFont: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 26, weight: .black), .foregroundColor: UIColor.label]
        let subTitleFont: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: UIColor.systemBlue]
        let labelFont: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: UIColor.secondaryLabel]
        let valFont: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .regular), .foregroundColor: UIColor.label]
        
        var y: CGFloat = 50
        
        // Header banner
        switch data.template {
        case .urgent:
            context.setFillColor(UIColor.systemRed.withAlphaComponent(0.12).cgColor)
            context.fill(CGRect(x: margin, y: y, width: contentWidth, height: 44))
            let urgentAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .black), .foregroundColor: UIColor.systemRed]
            "URGENT PRIORITY FACSIMILE".draw(at: CGPoint(x: margin + 12, y: y + 10), withAttributes: urgentAttr)
            y += 60
        case .professional:
            "FACSIMILE TRANSMITTAL".draw(at: CGPoint(x: margin, y: y), withAttributes: titleFont)
            y += 36
            "STANDARD BUSINESS COVER".draw(at: CGPoint(x: margin, y: y), withAttributes: subTitleFont)
            y += 30
        case .modern:
            "FAX TRANSMISSION".draw(at: CGPoint(x: margin, y: y), withAttributes: titleFont)
            y += 40
        case .minimal:
            "FAX COVER".draw(at: CGPoint(x: margin, y: y), withAttributes: titleFont)
            y += 36
        }
        
        // Horizontal divider
        context.setStrokeColor(UIColor.label.cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: standardPageSize.width - margin, y: y))
        context.strokePath()
        y += 20
        
        // Grid Table of fields
        let col1X = margin
        let col2X = margin + contentWidth / 2
        
        // TO section
        "TO:".draw(at: CGPoint(x: col1X, y: y), withAttributes: labelFont)
        (data.recipientName.isEmpty ? "Recipient" : data.recipientName).draw(at: CGPoint(x: col1X + 50, y: y), withAttributes: valFont)
        
        // FROM section
        "FROM:".draw(at: CGPoint(x: col2X, y: y), withAttributes: labelFont)
        (data.senderName.isEmpty ? "Sender" : data.senderName).draw(at: CGPoint(x: col2X + 55, y: y), withAttributes: valFont)
        y += 26
        
        "PHONE:".draw(at: CGPoint(x: col2X, y: y), withAttributes: labelFont)
        (data.senderPhone.isEmpty ? "N/A" : data.senderPhone).draw(at: CGPoint(x: col2X + 55, y: y), withAttributes: valFont)
        y += 26
        
        "PAGES:".draw(at: CGPoint(x: col1X, y: y), withAttributes: labelFont)
        "\(totalDocPages) (Including Cover)".draw(at: CGPoint(x: col1X + 50, y: y), withAttributes: valFont)
        
        "DATE:".draw(at: CGPoint(x: col2X, y: y), withAttributes: labelFont)
        DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none).draw(at: CGPoint(x: col2X + 55, y: y), withAttributes: valFont)
        y += 35
        
        // Subject line
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: standardPageSize.width - margin, y: y))
        context.strokePath()
        y += 15
        
        "SUBJECT:".draw(at: CGPoint(x: margin, y: y), withAttributes: labelFont)
        (data.subject.isEmpty ? "Fax Document Transmission" : data.subject).draw(at: CGPoint(x: margin + 70, y: y), withAttributes: valFont)
        y += 35
        
        // Notes Box
        "REMARKS & NOTES:".draw(at: CGPoint(x: margin, y: y), withAttributes: labelFont)
        y += 20
        
        let notesRect = CGRect(x: margin, y: y, width: contentWidth, height: 260)
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(1)
        context.stroke(notesRect)
        
        let notesText = data.notes.isEmpty ? "Please review the attached pages. Should any transmission issues occur, please contact sender." : data.notes
        let notesAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .regular), .foregroundColor: UIColor.label]
        notesText.draw(in: notesRect.insetBy(dx: 12, dy: 12), withAttributes: notesAttr)
    }
    
    private static func drawImageFit(image: UIImage, in context: CGContext) {
        let margin: CGFloat = 30
        let availableWidth = standardPageSize.width - margin * 2
        let availableHeight = standardPageSize.height - margin * 2
        
        let imgSize = image.size
        let widthScale = availableWidth / imgSize.width
        let heightScale = availableHeight / imgSize.height
        let scale = min(widthScale, heightScale)
        
        let drawWidth = imgSize.width * scale
        let drawHeight = imgSize.height * scale
        let drawX = margin + (availableWidth - drawWidth) / 2
        let drawY = margin + (availableHeight - drawHeight) / 2
        
        let rect = CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
        image.draw(in: rect)
    }
    
    private static func drawSignature(_ signature: UIImage, placement: SignaturePlacement, in context: CGContext) {
        let margin: CGFloat = 30
        let availableWidth = standardPageSize.width - margin * 2
        let availableHeight = standardPageSize.height - margin * 2
        
        let sigWidth = max(50, availableWidth * placement.relativeWidth)
        let sigHeight = sigWidth * (signature.size.height / max(1, signature.size.width))
        let sigX = margin + (availableWidth * placement.relativeX)
        let sigY = margin + (availableHeight * placement.relativeY)
        
        let sigRect = CGRect(x: sigX, y: sigY, width: sigWidth, height: sigHeight)
        signature.draw(in: sigRect)
    }
    
    private static func rotate(image: UIImage, byDegrees degrees: Double) -> UIImage {
        guard degrees != 0 else { return image }
        let radians = CGFloat(degrees * .pi / 180)
        var newSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians)).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return image }
        ctx.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        ctx.rotate(by: radians)
        image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
        let rotated = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return rotated
    }
}
