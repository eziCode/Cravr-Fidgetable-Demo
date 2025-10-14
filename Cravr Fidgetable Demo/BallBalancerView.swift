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
    @State private var isAgainstWall: Bool = false
    
    // Physics constants
    let gravity: CGFloat = 1000 // pixels per second squared
    let friction: CGFloat = 0.997 // Damping factor
    let wallStickiness: CGFloat = 0.85 // Friction when against wall
    let hapticMinInterval: TimeInterval = 0.015 // Minimum time between haptics (fast movement)
    let hapticMaxInterval: TimeInterval = 0.3 // Maximum time between haptics (slow movement)
    let wallHapticMinInterval: TimeInterval = 0.08 // Minimum time between wall hit haptics
    
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
        
        if distance >= maxDistance {
            // Ball hit the wall - stick to it
            let angle = atan2(newPosition.y, newPosition.x)
            
            // Place ball exactly at wall boundary
            newPosition = CGPoint(
                x: cos(angle) * maxDistance,
                y: sin(angle) * maxDistance
            )
            
            // Calculate if force is pulling away from wall
            // Normal vector at collision point (pointing inward)
            let normalX = -cos(angle)
            let normalY = -sin(angle)
            
            // Check if acceleration is pulling away from wall
            let accelDotNormal = ballAcceleration.x * normalX + ballAcceleration.y * normalY
            
            // Require a stronger pull force to detach from wall
            if accelDotNormal > 100 {
                // Force is strongly pulling away from wall - allow movement
                // Keep only velocity component that pulls away
                let velocityDotNormal = ballVelocity.x * normalX + ballVelocity.y * normalY
                if velocityDotNormal > 0 {
                    ballVelocity.x = velocityDotNormal * normalX * 0.5
                    ballVelocity.y = velocityDotNormal * normalY * 0.5
                } else {
                    // Zero out velocity - stick completely
                    ballVelocity.x = 0
                    ballVelocity.y = 0
                }
            } else {
                // Force pushing into wall or weak pull - completely stop the ball
                ballVelocity.x = 0
                ballVelocity.y = 0
            }
            
            // Only trigger wall hit haptic on the initial impact (not while stuck)
            if !isAgainstWall {
                triggerWallHaptic(at: angle)
                isAgainstWall = true
            }
        } else {
            // Ball is not against wall
            if isAgainstWall {
                // Just left the wall, reset flag
                isAgainstWall = false
            }
        }
        
        ballPosition = newPosition
        
        // Trigger movement haptics only if:
        // 1. Ball has moved from center AND
        // 2. Ball is not stuck against wall (or if it is, acceleration is pulling away)
        if distance > 5 {
            if !isAgainstWall {
                // Ball is freely moving
                triggerMovementHaptic()
            } else {
                // Ball is against wall - only vibrate if pulling away
                let angle = atan2(ballPosition.y, ballPosition.x)
                let normalX = -cos(angle)
                let normalY = -sin(angle)
                let accelDotNormal = ballAcceleration.x * normalX + ballAcceleration.y * normalY
                
                if accelDotNormal > 50 {
                    // Acceleration is pulling away from wall
                    triggerMovementHaptic()
                }
            }
        }
    }
    
    // MARK: - Haptics
    
    private func triggerMovementHaptic() {
        let speed = sqrt(ballVelocity.x * ballVelocity.x + ballVelocity.y * ballVelocity.y)
        let acceleration = sqrt(ballAcceleration.x * ballAcceleration.x + 
                               ballAcceleration.y * ballAcceleration.y)
        
        // Very low threshold to start haptics early
        guard speed > 5 || acceleration > 10 else { return }
        
        let currentTime = Date()
        
        // Normalize speed and acceleration (0.0 to 1.0)
        // Speed typically ranges from 0 to ~500 for moderate movement
        let normalizedSpeed = min(speed / 400.0, 1.0)
        // Acceleration typically ranges from 0 to ~1000
        let normalizedAcceleration = min(acceleration / 800.0, 1.0)
        
        // Use the higher of the two to determine intensity
        let intensity = max(normalizedSpeed, normalizedAcceleration)
        
        // Map intensity to haptic interval (inverse relationship)
        // Low intensity (barely moving) = long interval (infrequent haptics)
        // High intensity (fast moving) = short interval (frequent haptics)
        let hapticInterval = hapticMaxInterval - (intensity * (hapticMaxInterval - hapticMinInterval))
        
        if currentTime.timeIntervalSince(lastHapticTime) >= hapticInterval {
            // Scale haptic strength based on intensity
            if intensity < 0.3 {
                Haptics.shared.impact(.light) // Very gentle for slow movement
            } else if intensity < 0.6 {
                Haptics.shared.impact(.medium) // Medium for moderate movement
            } else {
                Haptics.shared.impact(.medium) // Keep medium for fast (not too overwhelming)
            }
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