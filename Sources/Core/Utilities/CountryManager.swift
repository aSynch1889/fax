import Foundation

public final class CountryManager {
    public static let shared = CountryManager()
    
    public let countries: [Country] = [
        Country(code: "US", name: "United States", dialCode: "+1", flag: "🇺🇸", sampleFormat: "(555) 123-4567"),
        Country(code: "CA", name: "Canada", dialCode: "+1", flag: "🇨🇦", sampleFormat: "(555) 234-5678"),
        Country(code: "GB", name: "United Kingdom", dialCode: "+44", flag: "🇬🇧", sampleFormat: "20 7946 0912"),
        Country(code: "DE", name: "Germany", dialCode: "+49", flag: "🇩🇪", sampleFormat: "30 123456"),
        Country(code: "JP", name: "Japan", dialCode: "+81", flag: "🇯🇵", sampleFormat: "3-1234-5678"),
        Country(code: "CN", name: "China", dialCode: "+86", flag: "🇨🇳", sampleFormat: "10 1234 5678"),
        Country(code: "FR", name: "France", dialCode: "+33", flag: "🇫🇷", sampleFormat: "1 23 45 67 89"),
        Country(code: "AU", name: "Australia", dialCode: "+61", flag: "🇦🇺", sampleFormat: "2 1234 5678"),
        Country(code: "IT", name: "Italy", dialCode: "+39", flag: "🇮🇹", sampleFormat: "06 1234567"),
        Country(code: "ES", name: "Spain", dialCode: "+34", flag: "🇪🇸", sampleFormat: "91 123 4567"),
        Country(code: "KR", name: "South Korea", dialCode: "+82", flag: "🇰🇷", sampleFormat: "2-123-4567"),
        Country(code: "BR", name: "Brazil", dialCode: "+55", flag: "🇧🇷", sampleFormat: "11 1234-5678"),
        Country(code: "MX", name: "Mexico", dialCode: "+52", flag: "🇲🇽", sampleFormat: "55 1234 5678"),
        Country(code: "IN", name: "India", dialCode: "+91", flag: "🇮🇳", sampleFormat: "11 2345 6789"),
        Country(code: "SG", name: "Singapore", dialCode: "+65", flag: "🇸🇬", sampleFormat: "6123 4567"),
        Country(code: "HK", name: "Hong Kong", dialCode: "+852", flag: "🇭🇰", sampleFormat: "2123 4567"),
        Country(code: "TW", name: "Taiwan", dialCode: "+886", flag: "🇹🇼", sampleFormat: "2 2345 6789"),
        Country(code: "NL", name: "Netherlands", dialCode: "+31", flag: "🇳🇱", sampleFormat: "20 123 4567"),
        Country(code: "CH", name: "Switzerland", dialCode: "+41", flag: "🇨🇭", sampleFormat: "44 123 45 67"),
        Country(code: "SE", name: "Sweden", dialCode: "+46", flag: "🇸🇪", sampleFormat: "8 123 45 67"),
        Country(code: "NO", name: "Norway", dialCode: "+47", flag: "🇳🇴", sampleFormat: "21 23 45 67"),
        Country(code: "DK", name: "Denmark", dialCode: "+45", flag: "🇩🇰", sampleFormat: "32 12 34 56"),
        Country(code: "NZ", name: "New Zealand", dialCode: "+64", flag: "🇳🇿", sampleFormat: "9 123 4567"),
        Country(code: "IE", name: "Ireland", dialCode: "+353", flag: "🇮🇪", sampleFormat: "1 234 5678"),
        Country(code: "BE", name: "Belgium", dialCode: "+32", flag: "🇧🇪", sampleFormat: "2 123 45 67"),
        Country(code: "AT", name: "Austria", dialCode: "+43", flag: "🇦🇹", sampleFormat: "1 123456"),
        Country(code: "PT", name: "Portugal", dialCode: "+351", flag: "🇵🇹", sampleFormat: "21 123 4567"),
        Country(code: "PL", name: "Poland", dialCode: "+48", flag: "🇵🇱", sampleFormat: "22 123 45 67"),
        Country(code: "IL", name: "Israel", dialCode: "+972", flag: "🇮🇱", sampleFormat: "3-123-4567"),
        Country(code: "AE", name: "United Arab Emirates", dialCode: "+971", flag: "🇦🇪", sampleFormat: "4 123 4567"),
        Country(code: "SA", name: "Saudi Arabia", dialCode: "+966", flag: "🇸🇦", sampleFormat: "11 123 4567"),
        Country(code: "ZA", name: "South Africa", dialCode: "+27", flag: "🇿🇦", sampleFormat: "11 123 4567"),
        Country(code: "AR", name: "Argentina", dialCode: "+54", flag: "🇦🇷", sampleFormat: "11 1234-5678"),
        Country(code: "CL", name: "Chile", dialCode: "+56", flag: "🇨🇱", sampleFormat: "2 1234 5678"),
        Country(code: "CO", name: "Colombia", dialCode: "+57", flag: "🇨🇴", sampleFormat: "1 123 4567"),
        Country(code: "TH", name: "Thailand", dialCode: "+66", flag: "🇹🇭", sampleFormat: "2 123 4567"),
        Country(code: "MY", name: "Malaysia", dialCode: "+60", flag: "🇲🇾", sampleFormat: "3-1234 5678"),
        Country(code: "PH", name: "Philippines", dialCode: "+63", flag: "🇵🇭", sampleFormat: "2 123 4567"),
        Country(code: "VN", name: "Vietnam", dialCode: "+84", flag: "🇻🇳", sampleFormat: "24 1234 5678"),
        Country(code: "ID", name: "Indonesia", dialCode: "+62", flag: "🇮🇩", sampleFormat: "21 1234567"),
        Country(code: "TR", name: "Turkey", dialCode: "+90", flag: "🇹🇷", sampleFormat: "212 123 4567"),
        Country(code: "GR", name: "Greece", dialCode: "+30", flag: "🇬🇷", sampleFormat: "21 0123 4567"),
        Country(code: "CZ", name: "Czech Republic", dialCode: "+420", flag: "🇨🇿", sampleFormat: "212 345 678"),
        Country(code: "HU", name: "Hungary", dialCode: "+36", flag: "🇭🇺", sampleFormat: "1 234 5678"),
        Country(code: "RO", name: "Romania", dialCode: "+40", flag: "🇷🇴", sampleFormat: "21 123 4567"),
        Country(code: "FI", name: "Finland", dialCode: "+358", flag: "🇫🇮", sampleFormat: "9 123 4567")
    ]
    
    public var defaultCountry: Country {
        let currentRegion = Locale.current.region?.identifier ?? "US"
        return countries.first(where: { $0.code == currentRegion }) ?? countries[0]
    }
    
    public func findCountry(by code: String) -> Country? {
        return countries.first(where: { $0.code.uppercased() == code.uppercased() })
    }
}
