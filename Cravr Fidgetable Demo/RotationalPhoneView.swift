//
//  RotationalPhoneView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/14/25.
//

import SwiftUI
import CoreMotion
import CoreHaptics

struct RotationalPhoneView: View {
    // Phone icon parameters
    let phoneSize: CGFloat = 80
    
    // State
    @State private var phoneRotation: Double = 0.0 // Current rotation angle in degrees
    @State private var lastRotation: Double = 0.0
    @State private var rotationSpeed: Double = 0.0 // Degrees per second
    
    // Motion manager
    @State private var motionManager: CMMotionManager? = {
        let manager = CMMotionManager()
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 1/60.0
        }
        return manager
    }()
    @State private var displayLink: Timer?
    
    // Haptic engine for continuous rotation feedback
    @State private var hapticEngine: CHHapticEngine?
    @State private var rotationPlayer: CHHapticAdvancedPatternPlayer?
    
    // Speed visualization
    @State private var speedIntensity: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Green background
            Color.green.ignoresSafeArea()
            
            // Phone icon in center
            ZStack {
                // Shadow/glow effect
                Image(systemName: "iphone.gen3")
                    .font(.system(size: phoneSize))
                    .foregroundColor(.black.opacity(0.3))
                    .blur(radius: 10)
                
                // Main phone icon
                Image(systemName: "iphone.gen3")
                    .font(.system(size: phoneSize))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10)
            }
            .rotationEffect(.degrees(phoneRotation))
            
            // Speed indicator (top)
            VStack {
                HStack(spacing: 4) {
                    ForEach(0..<10, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(speedIntensity > CGFloat(index) / 10.0 ? Color.white : Color.white.opacity(0.2))
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
            startRotationLoop()
        }
        .onDisappear {
            stopMotionManager()
            stopRotationLoop()
            stopRotationHaptic()
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
    
    // MARK: - Rotation Loop
    
    private func startRotationLoop() {
        guard displayLink == nil else { return }
        
        let timer = Timer(timeInterval: 1/60.0, repeats: true) { [self] _ in
            updateRotation()
        }
        displayLink = timer
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func stopRotationLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    private func updateRotation() {
        guard let motion = motionManager?.deviceMotion else { return }
        
        let dt: CGFloat = 1/60.0
        
        // Get rotation rate from device motion (radians per second)
        let rotationRate = motion.rotationRate
        
        // Use Z-axis rotation (spinning the phone flat on a table)
        // Convert from radians/sec to degrees/sec
        let rotationDelta = CGFloat(rotationRate.z) * (180.0 / .pi) * dt
        
        // Update rotation angle
        phoneRotation += rotationDelta
        
        // Keep rotation within 0-360 for display purposes (optional)
        if phoneRotation > 360 {
            phoneRotation -= 360
        } else if phoneRotation < 0 {
            phoneRotation += 360
        }
        
        // Calculate rotation speed (absolute value in degrees per second)
        rotationSpeed = abs(CGFloat(rotationRate.z) * (180.0 / .pi))
        
        // Update speed intensity for visualization (0-1 range)
        // Map speed to intensity: 0-360 degrees/sec -> 0-1
        speedIntensity = min(rotationSpeed / 360.0, 1.0)
        
        // Trigger haptic feedback based on rotation speed
        updateRotationHaptic(speed: rotationSpeed)
    }
    
    // MARK: - Rotation Haptics
    
    private func updateRotationHaptic(speed: CGFloat) {
        // Only provide haptic feedback if rotating at noticeable speed
        // Threshold at 8 degrees/sec for less sensitivity at start
        guard speed > 8.0 else {
            stopRotationHaptic()
            return
        }
        
        // Map speed to haptic intensity with LINEAR scaling for consistent feel
        // Speed range: 8-120 degrees/sec
        // Direct linear mapping so changes are immediate and proportional
        let normalizedSpeed = min((speed - 8.0) / 112.0, 1.0)
        
        // Use full intensity range with LINEAR scaling (0.35 to 1.0)
        // Lower base intensity for gentler start
        let hapticIntensity = Float(0.35 + (normalizedSpeed * 0.65))
        
        // Scale sharpness with speed for more dramatic effect (0.7 to 1.0)
        // Slow = smoother (0.7), fast = sharper/crisper (1.0)
        let sharpness: Float = 0.7 + (Float(normalizedSpeed) * 0.3)
        
        // If no player exists, create one
        if rotationPlayer == nil {
            createRotationHaptic(intensity: hapticIntensity, sharpness: sharpness)
        } else {
            // Update existing player
            updateContinuousRotationHaptic(intensity: hapticIntensity, sharpness: sharpness)
        }
    }
    
    private func createRotationHaptic(intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
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
            rotationPlayer = player
        } catch {
            print("Failed to create rotation haptic: \(error)")
        }
    }
    
    private func updateContinuousRotationHaptic(intensity: Float, sharpness: Float) {
        guard let player = rotationPlayer else { return }
        
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
            
            try player.sendParameters([intensityParam, sharpnessParam], atTime: 0)
        } catch {
            print("Failed to update rotation haptic: \(error)")
        }
    }
    
    private func stopRotationHaptic() {
        if let player = rotationPlayer {
            do {
                try player.stop(atTime: 0)
            } catch {
                print("Failed to stop rotation haptic: \(error)")
            }
            rotationPlayer = nil
        }
    }
}

#Preview {
    RotationalPhoneView()
}