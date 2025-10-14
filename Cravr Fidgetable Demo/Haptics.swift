//
//  Haptics.swift
//  Cravr Fidgetable Demo
//
//  Lightweight haptics helper using UIFeedbackGenerators.
//

import UIKit
import CoreHaptics

final class Haptics {
    static let shared = Haptics()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    // Ultra-light haptic generators for very subtle feedback
    private let ultraLightImpact = UIImpactFeedbackGenerator(style: .light)
    private let microImpact = UIImpactFeedbackGenerator(style: .light)
    
    // Core Haptics for advanced patterns
    private var hapticEngine: CHHapticEngine?
    private var continuousPlayer: CHHapticPatternPlayer?
    private var activePlayers: [Int: CHHapticPatternPlayer] = [:]
    private var inflationPlayers: [Int: CHHapticAdvancedPatternPlayer] = [:]

    private init() {
        prepareAll()
        setupCoreHaptics()
    }

    func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selection.prepare()
        notification.prepare()
        ultraLightImpact.prepare()
        microImpact.prepare()
    }
    
    private func setupCoreHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Core Haptics setup failed: \(error)")
        }
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            lightImpact.impactOccurred()
        case .medium:
            mediumImpact.impactOccurred()
        case .heavy:
            heavyImpact.impactOccurred()
        @unknown default:
            mediumImpact.impactOccurred()
        }
    }

    func bubblePopHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Bubble pop haptic failed: \(error)")
        }
    }

    func microHaptic() {
        selection.selectionChanged()
    }
    
    // Six unique haptic patterns for the six dot grid
    func dot1Haptic() {
        // Quick double tap - light then medium
        impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.impact(.medium)
        }
    }
    
    func dot2Haptic() {
        // Long heavy impact
        impact(.heavy)
    }
    
    func dot3Haptic() {
        // Triple light taps
        impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.impact(.light)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            self.impact(.light)
        }
    }
    
    func dot4Haptic() {
        // Medium then light crescendo
        impact(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.light)
        }
    }
    
    func dot5Haptic() {
        // Heavy then light decrescendo
        impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.impact(.light)
        }
    }
    
    func dot6Haptic() {
        // Rapid fire light taps
        impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            self.impact(.light)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.impact(.light)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            self.impact(.light)
        }
    }
    
    // Continuous haptic methods for six dot grid
    func startContinuousHaptic(for dotIndex: Int) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard hapticEngine != nil else { return }
        
        // Stop any existing haptic for this dot
        stopContinuousHaptic(for: dotIndex)
        
        let pattern = createContinuousPattern(for: dotIndex)
        
        do {
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
            activePlayers[dotIndex] = player
        } catch {
            print("Failed to start continuous haptic for dot \(dotIndex): \(error)")
        }
    }
    
    func stopContinuousHaptic(for dotIndex: Int) {
        if let player = activePlayers[dotIndex] {
            do {
                try player.stop(atTime: 0)
            } catch {
                print("Failed to stop haptic for dot \(dotIndex): \(error)")
            }
            activePlayers.removeValue(forKey: dotIndex)
        }
    }
    
    private func createContinuousPattern(for dotIndex: Int) -> CHHapticPattern {
        switch dotIndex {
        case 0: // Dot 1 - Quick double pulses
            return createDoublePulsePattern()
        case 1: // Dot 2 - Heavy continuous
            return createHeavyContinuousPattern()
        case 2: // Dot 3 - Triple pulse rhythm
            return createTriplePulsePattern()
        case 3: // Dot 4 - Medium-light crescendo
            return createCrescendoPattern()
        case 4: // Dot 5 - Heavy-light decrescendo
            return createDecrescendoPattern()
        case 5: // Dot 6 - Rapid fire
            return createRapidFirePattern()
        default:
            return createDoublePulsePattern()
        }
    }
    
    private func createDoublePulsePattern() -> CHHapticPattern {
        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0,
                duration: 1000
            )
        ]
        return try! CHHapticPattern(events: events, parameters: [])
    }
    
    private func createHeavyContinuousPattern() -> CHHapticPattern {
        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0,
                duration: 1000
            )
        ]
        return try! CHHapticPattern(events: events, parameters: [])
    }
    
    private func createTriplePulsePattern() -> CHHapticPattern {
        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0,
                duration: 1000
            )
        ]
        return try! CHHapticPattern(events: events, parameters: [])
    }
    
    private func createCrescendoPattern() -> CHHapticPattern {
        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0,
                duration: 1000
            )
        ]
        return try! CHHapticPattern(events: events, parameters: [])
    }
    
    private func createDecrescendoPattern() -> CHHapticPattern {
        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0,
                duration: 1000
            )
        ]
        return try! CHHapticPattern(events: events, parameters: [])
    }
    
    private func createRapidFirePattern() -> CHHapticPattern {
        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0,
                duration: 1000
            )
        ]
        return try! CHHapticPattern(events: events, parameters: [])
    }
    
    // MARK: - Inflation Haptics (for ThreeDotGridView)
    
    func startInflationHaptic(for dotIndex: Int) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard hapticEngine != nil else { return }
        
        // Stop any existing inflation haptic for this dot
        stopInflationHaptic(for: dotIndex)
        
        do {
            // Create a continuous haptic event with low initial intensity that user can feel
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 100 // Long duration
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makeAdvancedPlayer(with: pattern)
            
            try player?.start(atTime: 0)
            inflationPlayers[dotIndex] = player
        } catch {
            print("Failed to start inflation haptic for dot \(dotIndex): \(error)")
        }
    }
    
    func updateInflationHaptic(for dotIndex: Int, intensity: Float) {
        guard let player = inflationPlayers[dotIndex] else { return }
        
        // Map intensity (0.0 to 1.0) to haptic parameters
        // Start with noticeable vibrations and scale up to maximum
        // Intensity range: 0.6 to 1.0 (start noticeable, end at max)
        let scaledIntensity = 0.6 + (intensity * 0.4) // From 0.6 to 1.0
        let clampedIntensity = max(0.6, min(1.0, scaledIntensity))
        
        // Sharpness also increases as balloon inflates (0.2 to 1.0)
        let sharpness = 0.2 + (intensity * 0.8) // From 0.2 to 1.0
        
        do {
            // Update the continuous haptic's intensity and sharpness
            let intensityParam = CHHapticDynamicParameter(
                parameterID: .hapticIntensityControl,
                value: clampedIntensity,
                relativeTime: 0
            )
            
            let sharpnessParam = CHHapticDynamicParameter(
                parameterID: .hapticSharpnessControl,
                value: sharpness,
                relativeTime: 0
            )
            
            try player.sendParameters([intensityParam, sharpnessParam], atTime: 0)
        } catch {
            print("Failed to update inflation haptic for dot \(dotIndex): \(error)")
        }
    }
    
    func stopInflationHaptic(for dotIndex: Int) {
        if let player = inflationPlayers[dotIndex] {
            do {
                try player.stop(atTime: 0)
            } catch {
                print("Failed to stop inflation haptic for dot \(dotIndex): \(error)")
            }
            inflationPlayers.removeValue(forKey: dotIndex)
        }
    }
    
    // MARK: - Stop All Haptics
    
    /// Stops all active haptic players (continuous haptics and inflation haptics)
    func stopAllHaptics() {
        // Stop all continuous haptic players
        for (index, player) in activePlayers {
            do {
                try player.stop(atTime: 0)
            } catch {
                print("Failed to stop haptic for dot \(index): \(error)")
            }
        }
        activePlayers.removeAll()
        
        // Stop all inflation haptic players
        for (index, player) in inflationPlayers {
            do {
                try player.stop(atTime: 0)
            } catch {
                print("Failed to stop inflation haptic for dot \(index): \(error)")
            }
        }
        inflationPlayers.removeAll()
    }
}
