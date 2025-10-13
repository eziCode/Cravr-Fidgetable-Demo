//
//  RotatingDiscView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/13/25.
//

import SwiftUI

struct JoystickDiskView: View {
    @State private var diskPosition: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var lastHapticDirection: Direction? = nil
    @State private var maxResistance: CGFloat = 0.99
    @State private var lastHapticTime: Date = Date()
    @State private var isAnimating: Bool = false
    @State private var startDiskPosition: CGPoint = .zero
    
    private let maxDistance: CGFloat = 80
    private let hapticThreshold: CGFloat = 5 // Much more sensitive
    private let hapticCooldown: TimeInterval = 0.02 // Much more frequent (50x per second)
    
    enum Direction: CaseIterable {
        case up, down, left, right, upLeft, upRight, downLeft, downRight
        
        var hapticPattern: UIImpactFeedbackGenerator.FeedbackStyle {
            return .light
        }
    }
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            VStack(spacing: 40) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.0))
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 150, height: 150)
                        .offset(x: diskPosition.x, y: diskPosition.y)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    guard !isAnimating else { return }
                                    
                                    if !isDragging {
                                        startDiskPosition = diskPosition
                                    }
                                    
                                    isDragging = true
                                    
                                    let newPosition = CGPoint(
                                        x: startDiskPosition.x + value.translation.width,
                                        y: startDiskPosition.y + value.translation.height
                                    )
                                    updateDiskPosition(toward: newPosition)
                                    triggerDirectionalHaptics()
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    returnToCenter()
                                }
                        )
                        .scaleEffect(isDragging ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isDragging)
                }
            }
        }
        .onAppear {
            Haptics.shared.prepareAll()
        }
    }
    
    private func updateDiskPosition(toward target: CGPoint) {
        let dx = target.x
        let dy = target.y
        let distance = sqrt(dx * dx + dy * dy)
        
        let normalized = min(distance / maxDistance, 1.0)
        
        let resistanceStrength = 1.0 + (normalized * 4.0)
        
        let adjustedX = dx / resistanceStrength
        let adjustedY = dy / resistanceStrength
        
        var newPosition = CGPoint(x: adjustedX, y: adjustedY)
        
        let newDistance = sqrt(newPosition.x * newPosition.x + newPosition.y * newPosition.y)
        if newDistance > maxDistance {
            let angle = atan2(newPosition.y, newPosition.x)
            newPosition = CGPoint(
                x: cos(angle) * maxDistance,
                y: sin(angle) * maxDistance
            )
        }
        
        withAnimation(.linear(duration: 0.02)) {
            diskPosition = newPosition
        }
    }


    
    private func triggerDirectionalHaptics() {
        let distance = sqrt(diskPosition.x * diskPosition.x + diskPosition.y * diskPosition.y)
        
        guard distance > hapticThreshold else { return }
        
        let direction = getDirection(from: diskPosition)
        let currentTime = Date()
        
        let shouldTriggerHaptic = lastHapticDirection != direction || 
                                 currentTime.timeIntervalSince(lastHapticTime) >= hapticCooldown
        
        if shouldTriggerHaptic {
            // Use ultra-light haptic for more subtle feedback
            Haptics.shared.microHaptic()
            lastHapticDirection = direction
            lastHapticTime = currentTime
        }
    }
    
    private func getDirection(from position: CGPoint) -> Direction {
        let angle = atan2(position.y, position.x)
        let degrees = angle * 180 / .pi
        
        switch degrees {
        case -22.5..<22.5:
            return .right
        case 22.5..<67.5:
            return .upRight
        case 67.5..<112.5:
            return .up
        case 112.5..<157.5:
            return .upLeft
        case 157.5...180, -180..<(-157.5):
            return .left
        case -157.5..<(-112.5):
            return .downLeft
        case -112.5..<(-67.5):
            return .down
        case -67.5..<(-22.5):
            return .downRight
        default:
            return .right
        }
    }
    
    private func returnToCenter() {
        isAnimating = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.95, blendDuration: 0)) {
            diskPosition = .zero
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isAnimating = false
        }
        
        lastHapticDirection = nil
        lastHapticTime = Date()
    }
}

#Preview {
    JoystickDiskView()
}

