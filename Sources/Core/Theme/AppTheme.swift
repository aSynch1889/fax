import SwiftUI

public enum AppTheme {
    public static let primary = Color.blue
    public static let primaryDark = Color(red: 0.08, green: 0.45, blue: 0.90)
    public static let accent = Color(red: 0.11, green: 0.45, blue: 0.89)
    public static let success = Color.green
    public static let warning = Color.orange
    public static let danger = Color.red
    
    public static let background = Color(UIColor.systemBackground)
    public static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    public static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    public static let groupBackground = Color(UIColor.systemGroupedBackground)
    public static let secondaryGroupBackground = Color(UIColor.secondarySystemGroupedBackground)
    
    public static let cardShadowColor = Color.black.opacity(0.06)
}

public struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    public var cornerRadius: CGFloat = 16
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.secondaryGroupBackground)
                    .shadow(color: AppTheme.cardShadowColor, radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

public struct PrimaryButtonModifier: ViewModifier {
    public var isEnabled: Bool = true
    
    public func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isEnabled ? AppTheme.accent : Color.gray.opacity(0.5))
            )
            .shadow(color: isEnabled ? AppTheme.accent.opacity(0.3) : Color.clear, radius: 6, x: 0, y: 3)
    }
}

public extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButtonModifier(isEnabled: isEnabled))
    }
}
