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

    func selectionChanged() {
        selection.selectionChanged()
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
    }
    
    // Pop-it toy click
    func popClick() {
        impact(.light)
    }
    
    // Button click variations
    func buttonClick(intensity: Float = 0.5) {
        if intensity < 0.3 {
            impact(.light)
        } else if intensity < 0.7 {
            impact(.medium)
        } else {
            impact(.heavy)
        }
    }
    
    func spinningTick() {
        selectionChanged()
    }

    func joystickDrag() {
        // should be in the direction that the user is dragging the disk to
        impact(.light)
    }
    
    // Directional haptic feedback for joystick - all light for consistent feel
    func directionalHaptic(direction: JoystickDiskView.Direction) {
        impact(.light)
    }
    
    // Ultra-light haptic for more frequent feedback
    func ultraLightHaptic() {
        impact(.light)
    }
    
    // Micro haptic - extremely light and subtle
    func microHaptic() {
        // Use selection feedback for ultra-light feel
        selection.selectionChanged()
    }
    
    // Feather-light haptic - even lighter than light
    func featherHaptic() {
        // Very subtle selection feedback
        selection.selectionChanged()
    }
    
    // Rotation-based haptics
    func rotationTick(intensity: Float) {
        if intensity < 0.3 {
            impact(.light)
        } else if intensity < 0.7 {
            impact(.medium)
        } else {
            impact(.heavy)
        }
    }
}
