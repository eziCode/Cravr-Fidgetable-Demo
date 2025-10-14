//
//  ThreeDotGridView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/13/25.
//

import SwiftUI

struct ThreeDotGridView: View {
    private let screenWidth = UIScreen.main.bounds.size.width
    private let dotSize: CGFloat
    private let spacing: CGFloat
    private let inflationRate: CGFloat = 0.012 // How fast the balloon inflates per tick
    
    // Calculate max scale based on spacing to prevent overlap
    // Center-to-center distance is dotSize + spacing = 140
    // Max radius = 70 (half of center-to-center)
    // Current radius = 50 (half of dotSize)
    // Max scale = 70/50 = 1.4
    private let maxBalloonScale: CGFloat = 1.4
    
    init() {
        self.dotSize = screenWidth * 0.26 // 26% of screen width
        self.spacing = screenWidth * 0.10 // 10% of screen width
    }
    
    @State private var balloonScales: [CGFloat] = [1.0, 1.0, 1.0] // Scale for each of the 3 dots
    @State private var isPressed: [Bool] = [false, false, false] // Which dots are being held
    @State private var isVisible: [Bool] = [true, true, true] // Which dots are visible (for pop animation)
    @State private var inflationTimers: [Timer?] = [nil, nil, nil]
    @State private var reappearWorkItems: [DispatchWorkItem?] = [nil, nil, nil] // Track scheduled reappear tasks
    @State private var isViewActive: Bool = true // Track if view is active
    
    var body: some View {
        ZStack {
            VStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { index in
                    if isVisible[index] {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [colorForDot(index), colorForDot(index).opacity(0.7)]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: (dotSize / 2) * balloonScales[index]
                                )
                            )
                            .frame(width: dotSize, height: dotSize)
                            .shadow(color: colorForDot(index).opacity(0.6), radius: 15 * balloonScales[index])
                            .scaleEffect(balloonScales[index])
                            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: balloonScales[index])
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        if !isPressed[index] {
                                            startInflating(dotIndex: index)
                                        }
                                    }
                                    .onEnded { _ in
                                        stopInflating(dotIndex: index)
                                    }
                            )
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // Invisible placeholder to maintain layout
                        Circle()
                            .fill(Color.clear)
                            .frame(width: dotSize, height: dotSize)
                    }
                }
            }
        }
        .onAppear {
            isViewActive = true
            Haptics.shared.prepareAll()
        }
        .onDisappear {
            isViewActive = false
            
            // Cancel all scheduled reappear tasks
            for i in 0..<3 {
                reappearWorkItems[i]?.cancel()
                reappearWorkItems[i] = nil
            }
            
            // Clean up all timers and haptics immediately
            for i in 0..<3 {
                stopInflating(dotIndex: i)
            }
            
            // Force stop all haptics and sounds
            Haptics.shared.stopAllHaptics()
            SoundManager.shared.stopAllSounds()
            
            // Reset all state to defaults
            balloonScales = [1.0, 1.0, 1.0]
            isPressed = [false, false, false]
            isVisible = [true, true, true]
            inflationTimers = [nil, nil, nil]
            reappearWorkItems = [nil, nil, nil]
        }
    }
    
    private func colorForDot(_ index: Int) -> Color {
        switch index {
        case 0: return .cravrBlue
        case 1: return .cravrMaize
        case 2: return .cravrPumpkin
        default: return .cravrGreen
        }
    }
    
    private func startInflating(dotIndex: Int) {
        isPressed[dotIndex] = true
        
        // Start continuous haptic immediately
        Haptics.shared.startInflationHaptic(for: dotIndex)
        
        // Set initial low intensity
        let initialProgress = (balloonScales[dotIndex] - 1.0) / (maxBalloonScale - 1.0)
        Haptics.shared.updateInflationHaptic(for: dotIndex, intensity: Float(initialProgress))
        
        // Start the inflation timer
        inflationTimers[dotIndex] = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { timer in
            guard isPressed[dotIndex] else {
                timer.invalidate()
                return
            }
            
            // Inflate the balloon
            balloonScales[dotIndex] += inflationRate
            
            // Update haptic intensity based on inflation progress
            let progress = (balloonScales[dotIndex] - 1.0) / (maxBalloonScale - 1.0)
            Haptics.shared.updateInflationHaptic(for: dotIndex, intensity: Float(progress))
            
            // Check if balloon should pop (hit boundary)
            if balloonScales[dotIndex] >= maxBalloonScale {
                popBalloon(dotIndex: dotIndex)
            }
        }
    }
    
    private func stopInflating(dotIndex: Int) {
        isPressed[dotIndex] = false
        inflationTimers[dotIndex]?.invalidate()
        inflationTimers[dotIndex] = nil
        
        // Stop haptic
        Haptics.shared.stopInflationHaptic(for: dotIndex)
        
        // Deflate balloon back to normal
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            balloonScales[dotIndex] = 1.0
        }
    }
    
    private func popBalloon(dotIndex: Int) {
        // Stop inflation
        isPressed[dotIndex] = false
        inflationTimers[dotIndex]?.invalidate()
        inflationTimers[dotIndex] = nil
        
        // Stop continuous haptic
        Haptics.shared.stopInflationHaptic(for: dotIndex)
        
        // Big pop pulse - heavy impact + bubble pop haptic (only if view is active)
        if isViewActive {
            Haptics.shared.impact(.heavy)
            SoundManager.shared.playBubble() // Bubble pop sound
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [self] in
                if isViewActive {
                    Haptics.shared.bubblePopHaptic()
                }
            }
        }
        
        // Make balloon disappear
        withAnimation(.easeOut(duration: 0.1)) {
            isVisible[dotIndex] = false
        }
        
        // Reset scale
        balloonScales[dotIndex] = 1.0
        
        // Cancel any existing reappear work item for this dot
        reappearWorkItems[dotIndex]?.cancel()
        
        // Create new work item for reappearing
        let workItem = DispatchWorkItem { [self] in
            // Only reappear and trigger haptic if view is still active
            guard isViewActive else { return }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isVisible[dotIndex] = true
            }
            // Small pop haptic when balloon reappears
            Haptics.shared.impact(.light)
            SoundManager.shared.playDing() // Ding sound when reappearing
            
            // Clear the work item reference
            reappearWorkItems[dotIndex] = nil
        }
        
        reappearWorkItems[dotIndex] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
}

#Preview {
    ThreeDotGridView()
}