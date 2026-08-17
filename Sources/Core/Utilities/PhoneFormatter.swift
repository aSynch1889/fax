import Foundation

public enum PhoneFormatter {
    public static func format(number: String, sampleFormat: String) -> String {
        let digits = number.filter { $0.isNumber }
        var result = ""
        var digitIndex = digits.startIndex
        
        for char in sampleFormat {
            guard digitIndex < digits.endIndex else { break }
            if char.isNumber {
                result.append(digits[digitIndex])
                digitIndex = digits.index(after: digitIndex)
            } else {
                result.append(char)
            }
        }
        
        if digitIndex < digits.endIndex {
            result.append(contentsOf: digits[digitIndex...])
        }
        return result.isEmpty ? number : result
    }
    
    public static func clean(number: String) -> String {
        return number.filter { $0.isNumber || $0 == "+" }
    }
}
