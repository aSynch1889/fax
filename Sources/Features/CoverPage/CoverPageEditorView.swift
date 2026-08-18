import SwiftUI

public struct CoverPageEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding public var coverData: CoverPageData
    
    public init(coverData: Binding<CoverPageData>) {
        self._coverData = coverData
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("template_style")) {
                    Picker("template", selection: $coverData.template) {
                        ForEach(CoverPageTemplate.allCases) { t in
                            Text(t.localizedKey).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("sender_info")) {
                    TextField("sender_name", text: $coverData.senderName)
                    TextField("sender_phone", text: $coverData.senderPhone)
                }
                
                Section(header: Text("recipient_section")) {
                    TextField("recipient_name_placeholder", text: $coverData.recipientName)
                    TextField("company_org_placeholder", text: $coverData.recipientCompany)
                }
                
                Section(header: Text("subject")) {
                    TextField("subject", text: $coverData.subject)
                }
                
                Section(header: Text("notes_remarks")) {
                    TextEditor(text: $coverData.notes)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle(Text("edit_cover_page"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
