//
//  PhoneShakeView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/14/25.
//

import SwiftUI
import CoreMotion
import CoreHaptics

struct PhoneShakeView: View {
    // Phone icon parameters
    let phoneSize: CGFloat = 60
    let maxDistance: CGFloat = 120 // Max distance from center before strong deceleration
    
    // State
    @State private var phonePosition: CGPoint = .zero
    @State private var phoneVelocity: CGPoint = .zero
    @State private var phoneAcceleration: CGPoint = .zero
    
    // Motion manager
    @State private var motionManager: CMMotionManager? = {
        let manager = CMMotionManager()
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 1/60.0
        }
        return manager
    }()
    @State private var displayLink: Timer?
    
    // Shake detection
    @State private var shakeIntensity: CGFloat = 0.0
    @State private var lastShakeTime: Date = Date()
    
    // Haptic engine for continuous shake feedback
    @State private var hapticEngine: CHHapticEngine?
    @State private var shakePlayer: CHHapticAdvancedPatternPlayer?
    
    // Physics constants
    let gravity: CGFloat = 1200 // pixels per second squared
    let friction: CGFloat = 0.995 // Damping factor
    let boundaryStiffness: CGFloat = 0.5 // How strongly to push back from boundary
    let shakeThreshold: CGFloat = 1.2 // Acceleration threshold for shake detection (lower = more sensitive)
    let shakeDecayRate: CGFloat = 0.85 // How fast shake intensity decays
    
    var body: some View {
        ZStack {
            // Green background
            Color.green.ignoresSafeArea()
            
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Phone icon
                ZStack {
                    // Shadow/glow effect
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: phoneSize))
                        .foregroundColor(.black.opacity(0.3))
                        .blur(radius: 8)
                    
                    // Main phone icon
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: phoneSize))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                }
                .position(
                    x: center.x + phonePosition.x,
                    y: center.y + phonePosition.y
                )
                .rotationEffect(.degrees(Double(phonePosition.x / maxDistance) * 15))
            }
            
            // Shake intensity indicator (top)
            VStack {
                HStack(spacing: 4) {
                    ForEach(0..<10, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(shakeIntensity > CGFloat(index) / 10.0 ? Color.white : Color.white.opacity(0.2))
                            .frame(width: 20, height: 6)
                    }
                }
                .padding(.top, 60)
                Spacer()
            }
        }
        .task {
            setupHaptics()
            startMotionManager()
            startPhysicsLoop()
        }
        .onDisappear {
            stopMotionManager()
            stopPhysicsLoop()
            stopShakeHaptic()
        }
    }
    
    // MARK: - Haptics Setup
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine setup failed: \(error)")
        }
    }
    
    // MARK: - Motion Manager
    
    private func startMotionManager() {
        guard let manager = motionManager, !manager.isDeviceMotionActive else { return }
        manager.startDeviceMotionUpdates()
    }
    
    private func stopMotionManager() {
        motionManager?.stopDeviceMotionUpdates()
    }
    
    // MARK: - Physics Loop
    
    private func startPhysicsLoop() {
        guard displayLink == nil else { return }
        
        let timer = Timer(timeInterval: 1/60.0, repeats: true) { [self] _ in
            updatePhysics()
        }
        displayLink = timer
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func stopPhysicsLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    private func updatePhysics() {
        guard let motion = motionManager?.deviceMotion else { return }
        
        let dt: CGFloat = 1/60.0
        
        // Get tilt from device motion
        let tiltX = CGFloat(motion.gravity.x)
        let tiltY = CGFloat(motion.gravity.y)
        
        // Calculate acceleration from tilt
        let accelX = tiltX * gravity
        let accelY = -tiltY * gravity
        
        phoneAcceleration = CGPoint(x: accelX, y: accelY)
        
        // Apply soft boundary forces (asymptotic approach)
        let distance = sqrt(phonePosition.x * phonePosition.x + phonePosition.y * phonePosition.y)
        
        if distance > 0 {
            // Calculate boundary force that increases as we get closer to maxDistance
            // Using a smooth function that creates deceleration without hard stops
            let normalizedDist = distance / maxDistance
            
            // Start applying resistance much earlier (at 30% of max distance)
            // This ensures the phone never gets close to the actual boundary
            if normalizedDist > 0.3 {
                // Exponential resistance that grows stronger as we approach boundary
                // Using a higher power for stronger resistance
                let adjustedDist = (normalizedDist - 0.3) / 0.7 // Normalize to 0-1 range
                let resistanceFactor = pow(adjustedDist, 4) // Quartic for very smooth but strong resistance
                let boundaryForceX = -(phonePosition.x / distance) * resistanceFactor * gravity * boundaryStiffness
                let boundaryForceY = -(phonePosition.y / distance) * resistanceFactor * gravity * boundaryStiffness
                
                phoneAcceleration.x += boundaryForceX
                phoneAcceleration.y += boundaryForceY
            }
        }
        
        // Update velocity
        phoneVelocity.x += phoneAcceleration.x * dt
        phoneVelocity.y += phoneAcceleration.y * dt
        
        // Apply friction
        phoneVelocity.x *= friction
        phoneVelocity.y *= friction
        
        // Update position
        phonePosition.x += phoneVelocity.x * dt
        phonePosition.y += phoneVelocity.y * dt
        
        // Hard clamp to ensure phone NEVER goes beyond maxDistance
        let currentDistance = sqrt(phonePosition.x * phonePosition.x + phonePosition.y * phonePosition.y)
        if currentDistance > maxDistance {
            let angle = atan2(phonePosition.y, phonePosition.x)
            phonePosition.x = cos(angle) * maxDistance
            phonePosition.y = sin(angle) * maxDistance
            // Kill velocity when hitting hard boundary
            phoneVelocity = .zero
        }
        
        // Detect shaking
        detectShake(motion: motion)
        
        // Update shake intensity decay with faster decay rate
        if shakeIntensity > 0 {
            shakeIntensity *= shakeDecayRate
            
            // If intensity drops below threshold, stop haptics
            if shakeIntensity < 0.05 {
                shakeIntensity = 0
                stopShakeHaptic()
            }
        }
    }
    
    // MARK: - Shake Detection
    
    private func detectShake(motion: CMDeviceMotion) {
        // Use user acceleration (removes gravity) to detect sudden movements on ALL axes
        let userAccel = motion.userAcceleration
        
        // Calculate total acceleration magnitude from all three axes
        let accelMagnitude = sqrt(
            userAccel.x * userAccel.x +
            userAccel.y * userAccel.y +
            userAccel.z * userAccel.z
        )
        
        // Also check individual axes to ensure we catch shakes on any single axis
        let maxAxisAccel = max(abs(userAccel.x), abs(userAccel.y), abs(userAccel.z))
        
        // Use whichever is stronger: total magnitude or single axis
        let effectiveAccel = max(accelMagnitude, maxAxisAccel)
        
        // Update shake intensity
        if effectiveAccel > shakeThreshold {
            // Map acceleration to intensity (clamp to 0-1 range)
            // Using a more gradual scale for smoother intensity mapping
            let rawIntensity = (effectiveAccel - shakeThreshold) / 2.5
            let newIntensity = CGFloat(min(rawIntensity, 1.0))
            
            // Use max of current and new to create peaks
            shakeIntensity = max(shakeIntensity, newIntensity)
            
            // Trigger haptic feedback based on intensity and position
            triggerShakeHaptic(intensity: shakeIntensity)
            lastShakeTime = Date()
        } else {
            // If no shake detected and intensity is very low, ensure haptics stop
            if shakeIntensity < 0.1 {
                stopShakeHaptic()
            }
        }
    }
    
    // MARK: - Shake Haptics
    
    private func triggerShakeHaptic(intensity: CGFloat) {
        guard intensity > 0.1 else {
            stopShakeHaptic()
            return
        }
        
        // Calculate position-based modulation
        let distance = sqrt(phonePosition.x * phonePosition.x + phonePosition.y * phonePosition.y)
        let normalizedDist = min(distance / maxDistance, 1.0)
        
        // Haptic varies based on:
        // 1. Shake intensity (main factor)
        // 2. Distance from center (further from center = stronger haptics)
        let positionMultiplier = 0.5 + (normalizedDist * 0.5) // Range: 0.5 to 1.0
        let hapticIntensity = Float(intensity * positionMultiplier)
        
        // Sharpness increases with intensity for more "crisp" feel at high intensity
        let sharpness = Float(0.3 + (intensity * 0.7)) // Range: 0.3 to 1.0
        
        updateContinuousShakeHaptic(intensity: hapticIntensity, sharpness: sharpness)
    }
    
    private func updateContinuousShakeHaptic(intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        // If no player exists, create one
        if shakePlayer == nil {
            do {
                let event = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: 0,
                    duration: 100
                )
                
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try hapticEngine?.makeAdvancedPlayer(with: pattern)
                try player?.start(atTime: 0)
                shakePlayer = player
            } catch {
                print("Failed to create shake haptic: \(error)")
            }
        } else {
            // Update existing player
            do {
                let intensityParam = CHHapticDynamicParameter(
                    parameterID: .hapticIntensityControl,
                    value: intensity,
                    relativeTime: 0
                )
                
                let sharpnessParam = CHHapticDynamicParameter(
                    parameterID: .hapticSharpnessControl,
                    value: sharpness,
                    relativeTime: 0
                )
                
                try shakePlayer?.sendParameters([intensityParam, sharpnessParam], atTime: 0)
            } catch {
                print("Failed to update shake haptic: \(error)")
            }
        }
    }
    
    private func stopShakeHaptic() {
        if let player = shakePlayer {
            do {
                try player.stop(atTime: 0)
            } catch {
                print("Failed to stop shake haptic: \(error)")
            }
            shakePlayer = nil
        }
    }
}

#Preview {
    PhoneShakeView()
}