//
//  FourDotGridView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/13/25.
//

import SwiftUI

struct FourDotGridView: View {
    private let dotSize: CGFloat = 80
    private let gridSize: CGFloat = 200
    private let spacing: CGFloat = 20
    private let maxDistance: CGFloat = 30
    private let hapticCooldown: TimeInterval = 0.02
    
    enum Dot: Int, CaseIterable {
        case topLeft = 0, topRight, bottomLeft, bottomRight
        
        var hapticStyle: () -> Void {
            switch self {
            case .topLeft: return { Haptics.shared.microHaptic() }
            case .topRight: return { Haptics.shared.impact(.medium) }
            case .bottomLeft: return { Haptics.shared.bubblePopHaptic() }
            case .bottomRight: return { Haptics.shared.impact(.light) }
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    JoystickDiskView(
                        size: dotSize,
                        maxDistance: maxDistance,
                        hapticThreshold: 5,
                        hapticCooldown: hapticCooldown,
                        hapticAction: Dot(rawValue: index)?.hapticStyle ?? { },
                        showBackground: false
                    )
                    .offset(x: centerPosition(for: index).x, y: centerPosition(for: index).y)
                }
            }
            .frame(width: gridSize, height: gridSize)
        }
        .onAppear {
            Haptics.shared.prepareAll()
        }
    }
    
    // MARK: - Center positions of the 2x2 grid
    private func centerPosition(for index: Int) -> CGPoint {
        let row = index / 2
        let col = index % 2
        
        let totalSize = dotSize * 2 + spacing
        let startX = -totalSize / 2 + dotSize / 2
        let startY = -totalSize / 2 + dotSize / 2
        
        return CGPoint(
            x: startX + CGFloat(col) * (dotSize + spacing),
            y: startY + CGFloat(row) * (dotSize + spacing)
        )
    }
}

#Preview {
    FourDotGridView()
}
