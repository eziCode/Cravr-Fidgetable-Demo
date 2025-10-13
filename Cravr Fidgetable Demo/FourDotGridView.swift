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

    @State private var dotPositions: [CGPoint] = Array(repeating: .zero, count: 4)
    @State private var isDragging: [Bool] = Array(repeating: false, count: 4)
    @State private var startPositions: [CGPoint] = Array(repeating: .zero, count: 4)
    @State private var lastHapticTime: [Date] = Array(repeating: Date(), count: 4)
    
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
                    Circle()
                        .fill(Color.gray)
                        .frame(width: dotSize, height: dotSize)
                        .offset(x: centerPosition(for: index).x + dotPositions[index].x,
                                y: centerPosition(for: index).y + dotPositions[index].y)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    guard !isDragging[index] else { return }
                                    
                                    if !isDragging[index] { startPositions[index] = dotPositions[index] }
                                    isDragging[index] = true
                                    
                                    let newTarget = CGPoint(
                                        x: startPositions[index].x + value.translation.width,
                                        y: startPositions[index].y + value.translation.height
                                    )
                                    updateDotPosition(index: index, toward: newTarget)
                                    triggerHaptic(for: index)
                                }
                                .onEnded { _ in
                                    isDragging[index] = false
                                    returnDotToCenter(index)
                                }
                        )
                        .scaleEffect(isDragging[index] ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isDragging[index])
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
    
    // MARK: - Update dot position with resistance
    private func updateDotPosition(index: Int, toward target: CGPoint) {
        let dx = target.x
        let dy = target.y
        let distance = sqrt(dx*dx + dy*dy)
        
        let normalized = min(distance / maxDistance, 1.0)
        let resistance = 1.0 + (normalized * 4.0)
        
        var newPosition = CGPoint(x: dx / resistance, y: dy / resistance)
        
        let newDistance = sqrt(newPosition.x*newPosition.x + newPosition.y*newPosition.y)
        if newDistance > maxDistance {
            let angle = atan2(newPosition.y, newPosition.x)
            newPosition = CGPoint(x: cos(angle)*maxDistance, y: sin(angle)*maxDistance)
        }
        
        withAnimation(.linear(duration: 0.02)) {
            dotPositions[index] = newPosition
        }
    }
    
    // MARK: - Return dot to center
    private func returnDotToCenter(_ index: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
            dotPositions[index] = .zero
        }
    }
    
    // MARK: - Trigger haptics
    private func triggerHaptic(for index: Int) {
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastHapticTime[index]) >= hapticCooldown else { return }
        
        lastHapticTime[index] = currentTime
        if let dot = Dot(rawValue: index) { dot.hapticStyle() }
    }
}

#Preview {
    FourDotGridView()
}
