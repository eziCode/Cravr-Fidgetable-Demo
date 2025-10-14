//
//  BallBalancerView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/14/25.
//

import SwiftUI
import CoreMotion

struct BallBalancerView: View {
    // Dimensions
    let diskRadius: CGFloat = 150
    let ballSize: CGFloat = 40
    
    // Ball state
    @State private var ballPosition: CGPoint = .zero
    @State private var ballVelocity: CGPoint = .zero
    @State private var ballAcceleration: CGPoint = .zero
    
    // Motion manager
    @State private var motionManager: CMMotionManager?
    @State private var displayLink: Timer?
    
    // Haptic state
    @State private var lastHapticTime: Date = Date()
    @State private var lastWallHitTime: Date = Date()
    
    // Physics constants
    let gravity: CGFloat = 1200 // pixels per second squared
    let friction: CGFloat = 0.995 // Damping factor
    let wallBounceDamping: CGFloat = 0.6 // Energy loss on wall collision
    let hapticMinInterval: TimeInterval = 0.05 // Minimum time between haptics
    let wallHapticMinInterval: TimeInterval = 0.15 // Minimum time between wall hit haptics
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                ZStack {
                    // Light green disk (stationary)
                    Circle()
                        .fill(Color(red: 0.6, green: 1.0, blue: 0.6))
                        .frame(width: diskRadius * 2, height: diskRadius * 2)
                        .position(center)
                    
                    // Gray ball (moves with gyroscope)
                    Circle()
                        .fill(Color.gray)
                        .frame(width: ballSize, height: ballSize)
                        .shadow(color: .black.opacity(0.4), radius: 8)
                        .position(
                            x: center.x + ballPosition.x,
                            y: center.y + ballPosition.y
                        )
                }
            }
        }
        .onAppear {
            setupMotionManager()
            startPhysicsLoop()
            Haptics.shared.prepareAll()
        }
        .onDisappear {
            stopMotionManager()
            stopPhysicsLoop()
        }
    }
    
    // MARK: - Motion Manager Setup
    
    private func setupMotionManager() {
        let manager = CMMotionManager()
        motionManager = manager
        
        guard manager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        manager.deviceMotionUpdateInterval = 1/30.0 // 30 Hz
        manager.startDeviceMotionUpdates()
    }
    
    private func stopMotionManager() {
        motionManager?.stopDeviceMotionUpdates()
        motionManager = nil
    }
    
    // MARK: - Physics Loop
    
    private func startPhysicsLoop() {
        displayLink = Timer.scheduledTimer(withTimeInterval: 1/30.0, repeats: true) { _ in
            updatePhysics()
        }
    }
    
    private func stopPhysicsLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    private func updatePhysics() {
        guard let motion = motionManager?.deviceMotion else { return }
        
        let dt: CGFloat = 1/30.0 // Time step
        
        // Get gravity vector from device motion
        // gravity.x is positive when tilting right
        // gravity.y is positive when tilting toward user
        // We want ball to roll "downhill" so we use gravity directly
        let tiltX = CGFloat(motion.gravity.x)
        let tiltY = CGFloat(motion.gravity.y)
        
        // Calculate acceleration based on tilt (gravity pulls ball down the slope)
        let accelX = tiltX * gravity
        let accelY = -tiltY * gravity // Negative because screen y-axis is inverted
        
        // Store acceleration for haptic frequency calculation
        ballAcceleration = CGPoint(x: accelX, y: accelY)
        
        // Update velocity
        ballVelocity.x += accelX * dt
        ballVelocity.y += accelY * dt
        
        // Apply friction
        ballVelocity.x *= friction
        ballVelocity.y *= friction
        
        // Update position
        var newPosition = CGPoint(
            x: ballPosition.x + ballVelocity.x * dt,
            y: ballPosition.y + ballVelocity.y * dt
        )
        
        // Check for wall collisions
        let maxDistance = diskRadius - (ballSize / 2)
        let distance = sqrt(newPosition.x * newPosition.x + newPosition.y * newPosition.y)
        
        if distance > maxDistance {
            // Ball hit the wall - bounce back
            let angle = atan2(newPosition.y, newPosition.x)
            
            // Place ball at wall boundary
            newPosition = CGPoint(
                x: cos(angle) * maxDistance,
                y: sin(angle) * maxDistance
            )
            
            // Calculate reflection
            // Normal vector at collision point (pointing inward)
            let normalX = -cos(angle)
            let normalY = -sin(angle)
            
            // Reflect velocity
            let dotProduct = ballVelocity.x * normalX + ballVelocity.y * normalY
            ballVelocity.x = (ballVelocity.x - 2 * dotProduct * normalX) * wallBounceDamping
            ballVelocity.y = (ballVelocity.y - 2 * dotProduct * normalY) * wallBounceDamping
            
            // Trigger wall hit haptic
            triggerWallHaptic(at: angle)
        }
        
        ballPosition = newPosition
        
        // Trigger movement haptics
        if distance > 5 { // Only vibrate if ball has moved from center
            triggerMovementHaptic()
        }
    }
    
    // MARK: - Haptics
    
    private func triggerMovementHaptic() {
        let speed = sqrt(ballVelocity.x * ballVelocity.x + ballVelocity.y * ballVelocity.y)
        let acceleration = sqrt(ballAcceleration.x * ballAcceleration.x + 
                               ballAcceleration.y * ballAcceleration.y)
        
        guard speed > 50 || acceleration > 100 else { return }
        
        let currentTime = Date()
        
        // Map acceleration to haptic frequency
        // Higher acceleration = more frequent haptics
        let normalizedAcceleration = min(acceleration / 1000.0, 1.0)
        let hapticInterval = hapticMinInterval + (1.0 - normalizedAcceleration) * 0.1
        
        if currentTime.timeIntervalSince(lastHapticTime) >= hapticInterval {
            Haptics.shared.impact(.medium)
            lastHapticTime = currentTime
        }
    }
    
    private func triggerWallHaptic(at angle: CGFloat) {
        let currentTime = Date()
        
        guard currentTime.timeIntervalSince(lastWallHitTime) >= wallHapticMinInterval else {
            return
        }
        
        // Trigger a stronger haptic for wall collision
        Haptics.shared.impact(.heavy)
        lastWallHitTime = currentTime
    }
}

#Preview {
    BallBalancerView()
}