//
//  BallOnRingView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/14/25.
//

import SwiftUI

struct BallOnRingView: View {
    // Ring and ball dimensions
    let ringRadius: CGFloat = 150
    let ballSize: CGFloat = 40
    
    // Ball state
    @State private var angle: Double = 0 // Current angle in radians
    @State private var angularVelocity: Double = 0 // Radians per second
    @State private var isDragging: Bool = false
    @State private var lastDragAngle: Double = 0
    @State private var lastDragTime: Date = Date()
    @State private var lastHapticTime: Date = Date()
    
    // Animation timer
    @State private var displayLink: Timer?
    
    // Physics constants
    let friction: Double = 0.96 // Per frame friction (slightly less than 1 to slow down)
    let minVelocity: Double = 0.01 // Minimum velocity before stopping
    let hapticSpeedThreshold: Double = 0.1 // Minimum speed to trigger haptics
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                ZStack {
                    // The ring
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        .frame(width: ringRadius * 2, height: ringRadius * 2)
                        .position(center)
                    
                    // The ball
                    Circle()
                        .fill(Color.gray)
                        .frame(width: ballSize, height: ballSize)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                        .position(ballPosition(center: center))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleDrag(value: value, center: center)
                                }
                                .onEnded { _ in
                                    handleDragEnd()
                                }
                        )
                }
            }
        }
        .onAppear {
            Haptics.shared.prepareAll()
            startAnimationLoop()
        }
        .onDisappear {
            stopAnimationLoop()
            Haptics.shared.stopAllHaptics()
            
            // Reset all state to defaults
            angle = 0
            angularVelocity = 0
            isDragging = false
        }
    }
    
    // Calculate ball position based on angle
    private func ballPosition(center: CGPoint) -> CGPoint {
        let x = center.x + cos(angle) * ringRadius
        let y = center.y + sin(angle) * ringRadius
        return CGPoint(x: x, y: y)
    }
    
    // Handle drag gesture
    private func handleDrag(value: DragGesture.Value, center: CGPoint) {
        if !isDragging {
            isDragging = true
            lastDragAngle = angle
            lastDragTime = Date()
        }
        
        // Calculate angle from center to drag location
        let dx = value.location.x - center.x
        let dy = value.location.y - center.y
        let newAngle = atan2(dy, dx)
        
        // Calculate angular velocity based on change
        let currentTime = Date()
        let timeDelta = currentTime.timeIntervalSince(lastDragTime)
        
        if timeDelta > 0 {
            // Calculate shortest angular distance
            var angleDelta = newAngle - lastDragAngle
            
            // Normalize to [-π, π]
            while angleDelta > .pi { angleDelta -= 2 * .pi }
            while angleDelta < -.pi { angleDelta += 2 * .pi }
            
            // Calculate velocity
            angularVelocity = angleDelta / timeDelta
            
            // Trigger haptics based on speed
            triggerSpeedBasedHaptics()
        }
        
        angle = newAngle
        lastDragAngle = newAngle
        lastDragTime = currentTime
    }
    
    // Handle drag end - ball continues with momentum
    private func handleDragEnd() {
        isDragging = false
        // angularVelocity is already set from the last drag update
    }
    
    // Start animation loop for momentum
    private func startAnimationLoop() {
        displayLink = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
            updatePhysics()
        }
    }
    
    // Stop animation loop
    private func stopAnimationLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // Update physics each frame
    private func updatePhysics() {
        guard !isDragging else { return }
        
        // Apply friction
        angularVelocity *= friction
        
        // Stop if too slow
        if abs(angularVelocity) < minVelocity {
            angularVelocity = 0
            return
        }
        
        // Update angle
        angle += angularVelocity / 60.0 // Divide by frame rate
        
        // Normalize angle to [0, 2π]
        while angle > 2 * .pi { angle -= 2 * .pi }
        while angle < 0 { angle += 2 * .pi }
        
        // Trigger haptics based on speed
        triggerSpeedBasedHaptics()
    }
    
    // Trigger haptics based on ball speed
    private func triggerSpeedBasedHaptics() {
        let speed = abs(angularVelocity)
        
        guard speed > hapticSpeedThreshold else { return }
        
        let currentTime = Date()
        
        // Map speed to haptic frequency (faster = more frequent haptics)
        // Speed typically ranges from 0 to ~20 rad/s for fast movement
        let normalizedSpeed = min(speed / 10.0, 1.0)
        let hapticInterval = 0.15 * (1.0 - normalizedSpeed * 0.8) // Range from 0.15s to 0.03s
        
        if currentTime.timeIntervalSince(lastHapticTime) >= hapticInterval {
            triggerSpatialHaptic()
            lastHapticTime = currentTime
        }
    }
    
    // Trigger spatial haptic based on ball position
    private func triggerSpatialHaptic() {
        // Use heavy impact as base
        Haptics.shared.impact(.heavy)
        
        // TODO: In a future enhancement, we could use Core Haptics to create
        // truly spatial haptics based on the ball's position (angle)
        // For now, heavy impact provides good feedback
    }
}

#Preview {
    BallOnRingView()
}