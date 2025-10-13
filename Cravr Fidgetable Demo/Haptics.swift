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
}
