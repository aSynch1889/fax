import Foundation
import SwiftUI

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var selectedTab: TabItem = .send
    @Published public var isUnlocked: Bool = true
    
    public enum TabItem: Int, CaseIterable {
        case send = 0
        case documents = 1
        case history = 2
        case settings = 3
    }
}
