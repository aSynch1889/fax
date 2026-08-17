import SwiftUI

public struct ContactsListView: View {
    @ObservedObject var storage = StorageManager.shared
    @Environment(\.presentationMode) var presentationMode
    public var onSelect: ((FaxRecipient) -> Void)?
    @State private var showingAddSheet = false
    
    public init(onSelect: ((FaxRecipient) -> Void)? = nil) {
        self.onSelect = onSelect
    }
    
    public var body: some View {
        List {
            if storage.contacts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No saved contacts")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(storage.contacts) { contact in
                    Button(action: {
                        if let onSelect = onSelect {
                            onSelect(contact)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "building.2.crop.circle.fill")
                                .font(.title)
                                .foregroundColor(AppTheme.accent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if !contact.organization.isEmpty {
                                    Text(contact.organization)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(contact.formattedFullNumber)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if contact.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let contact = storage.contacts[index]
                        storage.deleteContact(id: contact.id)
                    }
                }
            }
        }
        .navigationTitle(Text("contacts_title"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContactSheet()
        }
    }
}

public struct AddContactSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var organization: String = ""
    @State private var selectedCountry: Country = CountryManager.shared.defaultCountry
    @State private var faxNumber: String = ""
    @State private var isFavorite: Bool = false
    @State private var showingCountryPicker = false
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipient Details")) {
                    TextField("Recipient / Company Name", text: $name)
                    TextField("Department / Org (Optional)", text: $organization)
                }
                
                Section(header: Text("Fax Number")) {
                    Button(action: { showingCountryPicker = true }) {
                        HStack {
                            Text("Country")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(selectedCountry.flag) \(selectedCountry.name) (\(selectedCountry.dialCode))")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    TextField("Fax Number", text: $faxNumber)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Toggle("Mark as Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle(Text("add_contact"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        let contact = FaxRecipient(
                            name: name.isEmpty ? "Contact" : name,
                            organization: organization,
                            countryCode: selectedCountry.code,
                            dialCode: selectedCountry.dialCode,
                            faxNumber: faxNumber,
                            isFavorite: isFavorite
                        )
                        StorageManager.shared.saveContact(contact)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(faxNumber.isEmpty)
                }
            }
            .sheet(isPresented: $showingCountryPicker) {
                CountryPickerView(selectedCountry: $selectedCountry)
            }
        }
    }
}
