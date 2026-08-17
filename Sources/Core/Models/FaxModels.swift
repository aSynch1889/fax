import Foundation
import SwiftUI
import CoreGraphics

public enum FilterType: String, Codable, CaseIterable, Identifiable {
    case original
    case blackAndWhite
    case grayscale
    case enhancedDoc
    
    public var id: String { rawValue }
    
    public var localizedKey: LocalizedStringKey {
        switch self {
        case .original: return "filter_original"
        case .blackAndWhite: return "filter_bw"
        case .grayscale: return "filter_grayscale"
        case .enhancedDoc: return "filter_enhanced"
        }
    }
}

public enum CoverPageTemplate: String, Codable, CaseIterable, Identifiable {
    case professional
    case modern
    case minimal
    case urgent
    
    public var id: String { rawValue }
    
    public var localizedKey: LocalizedStringKey {
        switch self {
        case .professional: return "template_professional"
        case .modern: return "template_modern"
        case .minimal: return "template_minimal"
        case .urgent: return "template_urgent"
        }
    }
}

public struct SignaturePlacement: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var relativeX: CGFloat // 0.0 - 1.0
    public var relativeY: CGFloat // 0.0 - 1.0
    public var relativeWidth: CGFloat // 0.0 - 1.0
    public var signatureImageData: Data
    
    public init(id: UUID = UUID(), relativeX: CGFloat, relativeY: CGFloat, relativeWidth: CGFloat, signatureImageData: Data) {
        self.id = id
        self.relativeX = relativeX
        self.relativeY = relativeY
        self.relativeWidth = relativeWidth
        self.signatureImageData = signatureImageData
    }
}

public struct FaxPage: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var imageFileName: String
    public var rotationAngle: Double = 0 // degrees: 0, 90, 180, 270
    public var filter: FilterType = .enhancedDoc
    public var signatures: [SignaturePlacement] = []
    
    public init(id: UUID = UUID(), imageFileName: String, rotationAngle: Double = 0, filter: FilterType = .enhancedDoc, signatures: [SignaturePlacement] = []) {
        self.id = id
        self.imageFileName = imageFileName
        self.rotationAngle = rotationAngle
        self.filter = filter
        self.signatures = signatures
    }
}

public struct CoverPageData: Codable, Hashable {
    public var isEnabled: Bool = false
    public var template: CoverPageTemplate = .professional
    public var senderName: String = ""
    public var senderPhone: String = ""
    public var recipientName: String = ""
    public var recipientCompany: String = ""
    public var subject: String = ""
    public var notes: String = ""
    
    public init(isEnabled: Bool = false, template: CoverPageTemplate = .professional, senderName: String = "", senderPhone: String = "", recipientName: String = "", recipientCompany: String = "", subject: String = "", notes: String = "") {
        self.isEnabled = isEnabled
        self.template = template
        self.senderName = senderName
        self.senderPhone = senderPhone
        self.recipientName = recipientName
        self.recipientCompany = recipientCompany
        self.subject = subject
        self.notes = notes
    }
}

public struct FaxRecipient: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var name: String
    public var organization: String
    public var countryCode: String // ISO 2 code, e.g. "US"
    public var dialCode: String // e.g. "+1"
    public var faxNumber: String // formatted or raw
    public var isFavorite: Bool = false
    
    public init(id: UUID = UUID(), name: String, organization: String = "", countryCode: String, dialCode: String, faxNumber: String, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.organization = organization
        self.countryCode = countryCode
        self.dialCode = dialCode
        self.faxNumber = faxNumber
        self.isFavorite = isFavorite
    }
    
    public var formattedFullNumber: String {
        return "\(dialCode) \(faxNumber)"
    }
}

public enum TransmissionStatus: String, Codable, CaseIterable {
    case queued
    case dialing
    case transmitting
    case delivered
    case failed
    
    public var localizedKey: LocalizedStringKey {
        switch self {
        case .queued: return "status_sending"
        case .dialing: return "status_dialing"
        case .transmitting: return "status_sending"
        case .delivered: return "status_delivered"
        case .failed: return "status_failed"
        }
    }
}

public struct FaxTransmissionRecord: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var confirmationCode: String
    public var recipient: FaxRecipient
    public var sentDate: Date
    public var completedDate: Date?
    public var pageCount: Int
    public var status: TransmissionStatus
    public var creditsUsed: Int
    public var transmissionDurationSeconds: Int
    public var receiptPDFFileName: String?
    public var subject: String
    
    public init(id: UUID = UUID(), confirmationCode: String = "FAX-\(Int.random(in: 100000...999999))", recipient: FaxRecipient, sentDate: Date = Date(), completedDate: Date? = nil, pageCount: Int, status: TransmissionStatus = .queued, creditsUsed: Int, transmissionDurationSeconds: Int = 0, receiptPDFFileName: String? = nil, subject: String = "") {
        self.id = id
        self.confirmationCode = confirmationCode
        self.recipient = recipient
        self.sentDate = sentDate
        self.completedDate = completedDate
        self.pageCount = pageCount
        self.status = status
        self.creditsUsed = creditsUsed
        self.transmissionDurationSeconds = transmissionDurationSeconds
        self.receiptPDFFileName = receiptPDFFileName
        self.subject = subject
    }
}

public struct FaxDocument: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var title: String
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
    public var pages: [FaxPage] = []
    public var coverPage: CoverPageData = CoverPageData()
    
    public init(id: UUID = UUID(), title: String = "Untitled Fax", createdAt: Date = Date(), updatedAt: Date = Date(), pages: [FaxPage] = [], coverPage: CoverPageData = CoverPageData()) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pages = pages
        self.coverPage = coverPage
    }
    
    public var totalPagesCount: Int {
        return (coverPage.isEnabled ? 1 : 0) + pages.count
    }
}

public struct Country: Identifiable, Hashable {
    public var id: String { code }
    public var code: String // ISO 2, e.g. "US"
    public var name: String
    public var dialCode: String // e.g. "+1"
    public var flag: String
    public var sampleFormat: String
    
    public init(code: String, name: String, dialCode: String, flag: String, sampleFormat: String = "(555) 000-0000") {
        self.code = code
        self.name = name
        self.dialCode = dialCode
        self.flag = flag
        self.sampleFormat = sampleFormat
    }
}
