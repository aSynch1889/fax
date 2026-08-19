import SwiftUI
import QuickLook

public struct HistoryListView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedSegment: Int = 0 // 0: Sent, 1: In-Progress/Outbox
    
    private var sentFaxes: [FaxTransmissionRecord] {
        storage.historyRecords.filter { $0.status == .delivered || $0.status == .failed }
    }
    
    private var outboxFaxes: [FaxTransmissionRecord] {
        storage.historyRecords.filter { $0.status == .queued || $0.status == .dialing || $0.status == .transmitting }
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("filter", selection: $selectedSegment) {
                    Text("history_sent").tag(0)
                    Text("history_outbox").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                let records = selectedSegment == 0 ? sentFaxes : outboxFaxes
                
                if records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary)
                        Text("no_history_title")
                            .font(.headline)
                        Text("no_history_desc")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(records) { record in
                        NavigationLink(destination: TransmissionDetailView(record: record)) {
                            HStack(spacing: 14) {
                                Image(systemName: record.status == .delivered ? "checkmark.circle.fill" : (record.status == .failed ? "xmark.circle.fill" : "antenna.radiowaves.left.and.right"))
                                    .font(.title2)
                                    .foregroundColor(record.status == .delivered ? .green : (record.status == .failed ? .red : AppTheme.accent))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.recipient.name.isEmpty ? record.recipient.formattedFullNumber : record.recipient.name)
                                        .font(.headline)
                                    
                                    Text(record.subject.isEmpty
                                         ? String(format: L10n.s("pages_count"), record.pageCount)
                                         : String(format: L10n.s("subject_pages_format"), record.subject, record.pageCount))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(record.confirmationCode)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(record.status.localizedKey)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(record.status == .delivered ? .green : (record.status == .failed ? .red : AppTheme.accent))
                                    
                                    Text(DateFormatter.localizedString(from: record.sentDate, dateStyle: .short, timeStyle: .short))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(Text("tab_history"))
        }
    }
}

public struct TransmissionDetailView: View {
    public var record: FaxTransmissionRecord
    @State private var receiptURL: URL?
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Header Card
                VStack(spacing: 12) {
                    Image(systemName: record.status == .delivered ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(record.status == .delivered ? .green : .red)
                    
                    Text(record.status.localizedKey)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(String(format: L10n.s("confirmation_code"), record.confirmationCode))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .glassCard()
                
                // Transmission Details
                VStack(alignment: .leading, spacing: 14) {
                    DetailRow(label: "recipient_name_label", value: record.recipient.name.isEmpty ? L10n.s("direct_fax_line") : record.recipient.name)
                    DetailRow(label: "destination_number", value: record.recipient.formattedFullNumber)
                    DetailRow(label: "country_code", value: record.recipient.countryCode)
                    DetailRow(label: "pages_transmitted", value: String(format: L10n.s("pages_count"), record.pageCount))
                    DetailRow(label: "credits_consumed", value: String(format: L10n.s("credits_count"), record.creditsUsed))
                    DetailRow(label: "duration", value: String(format: L10n.s("seconds_count"), record.transmissionDurationSeconds))
                    DetailRow(label: "sent_timestamp", value: DateFormatter.localizedString(from: record.sentDate, dateStyle: .medium, timeStyle: .medium))
                }
                .padding()
                .glassCard()
                
                // View Official Receipt Button
                Button(action: {
                    let receiptData = PDFGenerator.generateTransmissionReceipt(record: record)
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Receipt_\(record.confirmationCode).pdf")
                    try? receiptData.write(to: tempURL)
                    self.receiptURL = tempURL
                }) {
                    Label("view_receipt", systemImage: "doc.plaintext")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accent)
                        .cornerRadius(14)
                }
                .sheet(item: $receiptURL) { url in
                    QuickLookPreview(url: url)
                }
            }
            .padding()
        }
        .navigationTitle(Text("transmission_log"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

public struct QuickLookPreview: UIViewControllerRepresentable {
    public var url: URL
    
    public func makeUIViewController(context: Context) -> UINavigationController {
        let ql = QLPreviewController()
        ql.dataSource = context.coordinator
        let nav = UINavigationController(rootViewController: ql)
        return nav
    }
    
    public func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    public class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        
        public func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}

public struct DetailRow: View {
    public var label: LocalizedStringKey
    public var value: String
    
    public var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
