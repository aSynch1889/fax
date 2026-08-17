import SwiftUI

public struct CountryPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding public var selectedCountry: Country
    @State private var searchText = ""
    
    public init(selectedCountry: Binding<Country>) {
        self._selectedCountry = selectedCountry
    }
    
    private var filteredCountries: [Country] {
        let list = CountryManager.shared.countries
        if searchText.isEmpty { return list }
        return list.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.dialCode.contains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public var body: some View {
        NavigationView {
            List(filteredCountries) { country in
                Button(action: {
                    selectedCountry = country
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 14) {
                        Text(country.flag)
                            .font(.title2)
                        
                        Text(country.name)
                            .foregroundColor(.primary)
                            .font(.body)
                        
                        Spacer()
                        
                        Text(country.dialCode)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        if country.code == selectedCountry.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppTheme.accent)
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .searchable(text: $searchText, prompt: Text("Search country or code"))
            .navigationTitle(Text("country_region"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("done")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}
