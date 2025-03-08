//
//  Theme.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import SwiftUI

// App theme with primarily white and cream/beige accents
struct AppTheme {
    // MARK: - Colors
    static let primaryBackground = Color.white
    static let secondaryBackground = Color(hex: "F5F5DC") // Light beige
    static let accentColor = Color(hex: "DCDCBC") // Darker beige
    static let textPrimary = Color.black
    static let textSecondary = Color.gray
    
    // Button styles
    static let primaryButtonBackground = Color(hex: "E6E6C8") // Light beige
    static let secondaryButtonBackground = Color(hex: "F8F8F0") // Very light beige
    
    // Exercise category colors
    static let strengthColor = Color(hex: "D4D4AA")
    static let cardioColor = Color(hex: "F0E6D2")
    static let flexibilityColor = Color(hex: "E6D8D8")
    
    // Workout phase colors
    static let warmupColor = Color(hex: "FFE4B5") // Lighter color for warmup
    static let mainColor = Color(hex: "E6CCAB") // Stronger color for main workout
    static let cooldownColor = Color(hex: "E6E6D2") // Subtle color for cooldown
    
    // Progress indicators
    static let progressBackground = Color(hex: "F5F5DC")
    static let progressForeground = Color(hex: "CDCDAB")
    
    // MARK: - Fonts
    static let titleFont = Font.system(.title, design: .rounded).weight(.semibold)
    static let headlineFont = Font.system(.headline, design: .rounded)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)
    
    // MARK: - Dimensions
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let iconSize: CGFloat = 24
    
    // MARK: - Animations
    static let standardAnimation = Animation.easeInOut(duration: 0.2)
    
    // MARK: - Shadows
    static let subtleShadow = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    
    // MARK: - Helpers
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        func apply() -> some ViewModifier {
            return ShadowModifier(shadow: self)
        }
    }
    
    private struct ShadowModifier: ViewModifier {
        let shadow: Shadow
        
        func body(content: Content) -> some View {
            content
                .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryButtonBackground)
            .foregroundColor(AppTheme.textPrimary)
            .cornerRadius(AppTheme.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(AppTheme.standardAnimation, value: configuration.isPressed)
            .modifier(AppTheme.subtleShadow.apply())
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.secondaryButtonBackground)
            .foregroundColor(AppTheme.textPrimary)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.accentColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(AppTheme.standardAnimation, value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(AppTheme.smallPadding)
            .background(
                Circle()
                    .fill(AppTheme.secondaryButtonBackground)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(AppTheme.standardAnimation, value: configuration.isPressed)
    }
}

// MARK: - Card Styles
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.primaryBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.accentColor.opacity(0.5), lineWidth: 1)
            )
            .modifier(AppTheme.subtleShadow.apply())
    }
}

// MARK: - Color Extensions
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
