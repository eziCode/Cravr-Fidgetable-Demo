//
//  CravrColors.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/14/25.
//

import SwiftUI

extension Color {
    // Cravr Brand Colors
    static let cravrGreen = Color(hex: "1CD91F")
    static let cravrBlue = Color(hex: "92DCE5")
    static let cravrMaize = Color(hex: "F7EC59")
    static let cravrPumpkin = Color(hex: "FA7921")
    
    // Dark mode background
    static let cravrDarkBackground = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let cravrDarkSurface = Color(red: 0.12, green: 0.12, blue: 0.15)
    
    // Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

