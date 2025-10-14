//
//  SixDotGridView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/13/25.
//

import SwiftUI

struct SixDotGridView: View {
    private let screenWidth = UIScreen.main.bounds.size.width
    private let dotSize: CGFloat
    private let gridSpacing: CGFloat
    private let rows = 3
    private let cols = 2
    
    init() {
        self.dotSize = screenWidth * 0.22 // 22% of screen width
        self.gridSpacing = screenWidth * 0.05 // 5% of screen width
    }
    
    @State private var toggledDots: Set<Int> = []
    
    enum Dot: Int, CaseIterable {
        case dot1 = 0, dot2, dot3, dot4, dot5, dot6
        
        var hapticAction: () -> Void {
            switch self {
            case .dot1: return { Haptics.shared.dot1Haptic() }
            case .dot2: return { Haptics.shared.dot2Haptic() }
            case .dot3: return { Haptics.shared.dot3Haptic() }
            case .dot4: return { Haptics.shared.dot4Haptic() }
            case .dot5: return { Haptics.shared.dot5Haptic() }
            case .dot6: return { Haptics.shared.dot6Haptic() }
            }
        }
        
        var color: Color {
            switch self {
            case .dot1: return .cravrGreen
            case .dot2: return .cravrBlue
            case .dot3: return .cravrMaize
            case .dot4: return .cravrPumpkin
            case .dot5: return .cravrGreen
            case .dot6: return .cravrBlue
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.cravrDarkBackground.ignoresSafeArea()
            
            VStack(spacing: gridSpacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: gridSpacing) {
                        ForEach(0..<cols, id: \.self) { col in
                            let index = row * cols + col
                            let dot = Dot(rawValue: index)!
                            
                            Circle()
                                .fill(
                                    toggledDots.contains(index) ? 
                                    RadialGradient(
                                        gradient: Gradient(colors: [dot.color, dot.color.opacity(0.7)]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: dotSize / 2
                                    ) :
                                    RadialGradient(
                                        gradient: Gradient(colors: [Color.cravrDarkSurface, Color.cravrDarkSurface]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: dotSize / 2
                                    )
                                )
                                .frame(width: dotSize, height: dotSize)
                                .shadow(color: toggledDots.contains(index) ? dot.color.opacity(0.6) : .clear, radius: 15)
                                .scaleEffect(toggledDots.contains(index) ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: toggledDots.contains(index))
                                .onTapGesture {
                                    toggleDot(index: index, dot: dot)
                                }
                        }
                    }
                }
            }
        }
        .onAppear {
            Haptics.shared.prepareAll()
        }
        .onDisappear {
            // Immediately stop all continuous haptics and sounds
            Haptics.shared.stopAllHaptics()
            SoundManager.shared.stopAllSounds()
            
            // Reset state when tab changes
            toggledDots.removeAll()
        }
    }
    
    private func toggleDot(index: Int, dot: Dot) {
        if toggledDots.contains(index) {
            toggledDots.remove(index)
            Haptics.shared.stopContinuousHaptic(for: index)
            SoundManager.shared.playPop() // Sound when turning off
        } else {
            toggledDots.insert(index)
            Haptics.shared.startContinuousHaptic(for: index)
            SoundManager.shared.playClick() // Sound when turning on
        }
    }
}

#Preview {
    SixDotGridView()
}