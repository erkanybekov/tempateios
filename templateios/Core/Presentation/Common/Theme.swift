import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        static let primary = Color.green
        static let secondary = Color(hex: "97ce4c") // Rick and Morty green
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let text = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        
        // Status colors
        static let alive = Color.green
        static let dead = Color.red
        static let unknown = Color.gray
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let headline = Font.headline
        static let body = Font.body
        static let subheadline = Font.subheadline
        static let caption = Font.caption
    }
    
    // MARK: - Layout
    struct Layout {
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 24
        static let cellSpacing: CGFloat = 16
    }
    
    // MARK: - Animations
    struct Animations {
        static let standard = Animation.easeInOut(duration: 0.3)
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 