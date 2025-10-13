//  SixDotGridView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/13/25.
//

import SwiftUI

struct SixDotGridView: View {
    private let dotSize: CGFloat = 70
    private let gridSpacing: CGFloat = 20
    private let rows = 3
    private let cols = 2
    
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
            case .dot1: return .red
            case .dot2: return .blue
            case .dot3: return .brown
            case .dot4: return .orange
            case .dot5: return .purple
            case .dot6: return .pink
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            VStack(spacing: gridSpacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: gridSpacing) {
                        ForEach(0..<cols, id: \.self) { col in
                            let index = row * cols + col
                            let dot = Dot(rawValue: index)!
                            
                            Circle()
                                .fill(toggledDots.contains(index) ? dot.color : Color.gray)
                                .frame(width: dotSize, height: dotSize)
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
    }
    
    private func toggleDot(index: Int, dot: Dot) {
        if toggledDots.contains(index) {
            toggledDots.remove(index)
            Haptics.shared.stopContinuousHaptic(for: index)
        } else {
            toggledDots.insert(index)
            Haptics.shared.startContinuousHaptic(for: index)
        }
    }
}

#Preview {
    SixDotGridView()
}