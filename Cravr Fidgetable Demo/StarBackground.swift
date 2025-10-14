//
//  StarBackground.swift
//  Nomigo
//
//  Created by Nicholas Candello on 7/23/25.
//

import SwiftUI

struct StarBackground: View {
    let starCount: Int
    let minStarSize: CGFloat
    let maxStarSize: CGFloat
    let opacity: Double
    
    @State private var stars: [Star] = []
    
    init(starCount: Int = 100, minStarSize: CGFloat = 1, maxStarSize: CGFloat = 3, opacity: Double = 0.8) {
        self.starCount = starCount
        self.minStarSize = minStarSize
        self.maxStarSize = maxStarSize
        self.opacity = opacity
    }
    
    var body: some View {
        ZStack {
            // Background color with subtle gradient
            LinearGradient(
                colors: [
                    Color(hex: "00361e"),
                    Color(hex: "002818"),
                    Color(hex: "001f12")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Stars - using ZStack for better performance
            ZStack {
                ForEach(stars) { star in
                    StarView(star: star)
                }
            }
            .onAppear {
                generateStars()
            }
        }
    }
    
    private func generateStars() {
        let positions = getEvenlySpacedPositions(count: starCount)
        
        stars = positions.enumerated().map { index, position in
            let starType = StarType.allCases.randomElement() ?? .twinkle
            let baseOpacity = Double.random(in: 0.3...opacity)
            
            return Star(
                id: UUID(),
                x: position.x,
                y: position.y,
                size: CGFloat.random(in: minStarSize...maxStarSize),
                opacity: baseOpacity,
                animationDelay: Double.random(in: 0...8),
                animationDuration: Double.random(in: 4.0...8.0),
                type: starType,
                brightness: starType == .bright ? Double.random(in: 0.9...1.0) : baseOpacity
            )
        }
    }
    
    private func getEvenlySpacedPositions(count: Int) -> [CGPoint] {
        // Pre-defined lookup table of evenly distributed positions (normalized 0-1)
        let normalizedPositions: [(x: Double, y: Double)] = [
            (0.12, 0.15), (0.34, 0.08), (0.67, 0.23), (0.89, 0.11), (0.21, 0.41),
            (0.78, 0.37), (0.45, 0.29), (0.91, 0.52), (0.08, 0.58), (0.56, 0.61),
            (0.29, 0.73), (0.84, 0.69), (0.13, 0.86), (0.71, 0.91), (0.43, 0.84),
            (0.96, 0.78), (0.19, 0.95), (0.62, 0.03), (0.85, 0.19), (0.37, 0.12),
            (0.74, 0.45), (0.15, 0.31), (0.58, 0.38), (0.92, 0.24), (0.26, 0.55),
            (0.69, 0.67), (0.41, 0.74), (0.87, 0.81), (0.04, 0.88), (0.53, 0.95),
            (0.76, 0.06), (0.32, 0.18), (0.64, 0.34), (0.11, 0.47), (0.88, 0.41),
            (0.47, 0.63), (0.73, 0.76), (0.25, 0.89), (0.59, 0.82), (0.93, 0.95),
            (0.16, 0.07), (0.81, 0.13), (0.38, 0.26), (0.55, 0.19), (0.77, 0.32),
            (0.23, 0.48), (0.65, 0.54), (0.42, 0.67), (0.86, 0.73), (0.09, 0.79),
            (0.71, 0.85), (0.28, 0.92), (0.52, 0.04), (0.94, 0.17), (0.17, 0.33),
            (0.63, 0.46), (0.39, 0.59), (0.82, 0.65), (0.14, 0.71), (0.68, 0.78),
            (0.45, 0.91), (0.91, 0.84), (0.33, 0.97), (0.76, 0.02), (0.22, 0.14),
            (0.57, 0.27), (0.83, 0.39), (0.18, 0.52), (0.49, 0.58), (0.75, 0.71),
            (0.31, 0.77), (0.87, 0.83), (0.13, 0.96), (0.61, 0.09), (0.95, 0.21),
            (0.41, 0.35), (0.67, 0.48), (0.24, 0.61), (0.79, 0.54), (0.46, 0.87),
            (0.92, 0.73), (0.15, 0.79), (0.58, 0.92), (0.84, 0.05), (0.37, 0.18),
            (0.72, 0.31), (0.28, 0.44), (0.64, 0.57), (0.51, 0.7), (0.86, 0.76),
            (0.12, 0.83), (0.48, 0.96), (0.74, 0.12), (0.35, 0.25), (0.81, 0.38),
            (0.27, 0.51), (0.53, 0.64), (0.89, 0.77), (0.16, 0.9), (0.62, 0.03)
        ]
        
        // Take only the number of positions we need
        let selectedPositions = Array(normalizedPositions.prefix(min(count, normalizedPositions.count)))
        
        // Convert normalized positions to screen coordinates
        var finalPositions: [CGPoint] = []
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for position in selectedPositions {
            let x = position.x * Double(screenWidth)
            let y = position.y * Double(screenHeight)
            finalPositions.append(CGPoint(x: x, y: y))
        }
        
        // If we need more positions than in our lookup table, repeat and offset
        var positionIndex = 0
        for i in selectedPositions.count..<count {
            if positionIndex >= selectedPositions.count {
                positionIndex = 0
            }
            
            let basePosition = selectedPositions[positionIndex]
            
            // Add slight variation for repeated positions to avoid exact duplicates
            let offsetMultiplier = Double(i / selectedPositions.count)
            let xOffset = (offsetMultiplier * 0.05) - 0.025 // Small offset between -2.5% and +2.5%
            let yOffset = (offsetMultiplier * 0.05) - 0.025
            
            let finalX = max(0.02, min(0.98, basePosition.x + xOffset)) * Double(screenWidth)
            let finalY = max(0.02, min(0.98, basePosition.y + yOffset)) * Double(screenHeight)
            
            finalPositions.append(CGPoint(x: finalX, y: finalY))
            positionIndex += 1
        }
        
        return finalPositions
    }
}

enum StarType: CaseIterable {
    case twinkle      // Size changes
    case fade         // Opacity changes
    case bright       // Stays bright and constant
    case pulse        // Slow opacity pulse
    case shimmer      // Both size and opacity change subtly
}

struct StarView: View {
    let star: Star
    @State private var isAnimating = false
    
    var body: some View {
        Group {
            switch star.type {
            case .twinkle:
                Circle()
                    .fill(Color.white.opacity(star.opacity))
                    .frame(width: star.size, height: star.size)
                    .scaleEffect(isAnimating ? 1.2 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: star.animationDuration)
                            .repeatForever(autoreverses: true)
                            .delay(star.animationDelay),
                        value: isAnimating
                    )
                    
            case .fade:
                Circle()
                    .fill(Color.white.opacity(isAnimating ? star.brightness : star.opacity * 0.5))
                    .frame(width: star.size, height: star.size)
                    .animation(
                        Animation.easeInOut(duration: star.animationDuration)
                            .repeatForever(autoreverses: true)
                            .delay(star.animationDelay),
                        value: isAnimating
                    )
                    
            case .bright:
                Circle()
                    .fill(Color.white.opacity(star.brightness))
                    .frame(width: star.size, height: star.size)
                    .shadow(color: .white.opacity(0.2), radius: star.size * 0.3)
                    
            case .pulse:
                Circle()
                    .fill(Color.white.opacity(star.opacity))
                    .frame(width: star.size, height: star.size)
                    .opacity(isAnimating ? 0.9 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true)
                            .delay(star.animationDelay + Double.random(in: 0...star.animationDuration)),
                        value: isAnimating
                    )
                    
            case .shimmer:
                Circle()
                    .fill(Color.white.opacity(isAnimating ? star.brightness : star.opacity))
                    .frame(width: star.size, height: star.size)
                    .scaleEffect(isAnimating ? 1.1 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: star.animationDuration)
                            .repeatForever(autoreverses: true)
                            .delay(star.animationDelay),
                        value: isAnimating
                    )
            }
        }
        .position(x: star.x, y: star.y)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + star.animationDelay) {
            // Only start animation for non-bright stars
            if star.type != .bright {
                isAnimating = true
            }
        }
    }
}

struct Star: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let animationDelay: Double
    let animationDuration: Double
    let type: StarType
    let brightness: Double
}

#Preview {
    StarBackground()
}

#Preview("Dense Stars") {
    StarBackground(starCount: 200, minStarSize: 0.5, maxStarSize: 2.5)
}

#Preview("Sparse Stars") {
    StarBackground(starCount: 50, minStarSize: 2, maxStarSize: 4)
}
