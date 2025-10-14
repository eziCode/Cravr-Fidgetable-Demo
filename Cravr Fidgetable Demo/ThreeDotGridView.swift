//
//  ThreeDotGridView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/13/25.
//

import SwiftUI

struct ThreeDotGridView: View {
    private let dotSize: CGFloat = 80
    private let spacing: CGFloat = 40
    private let inflationRate: CGFloat = 0.012 // How fast the balloon inflates per tick
    
    // Calculate max scale based on spacing to prevent overlap
    // Center-to-center distance is dotSize + spacing = 120
    // Max radius = 60 (half of center-to-center)
    // Current radius = 40 (half of dotSize)
    // Max scale = 60/40 = 1.5
    private let maxBalloonScale: CGFloat = 1.5
    
    @State private var balloonScales: [CGFloat] = [1.0, 1.0, 1.0] // Scale for each of the 3 dots
    @State private var isPressed: [Bool] = [false, false, false] // Which dots are being held
    @State private var isVisible: [Bool] = [true, true, true] // Which dots are visible (for pop animation)
    @State private var inflationTimers: [Timer?] = [nil, nil, nil]
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            VStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { index in
                    if isVisible[index] {
                        Circle()
                            .fill(colorForDot(index))
                            .frame(width: dotSize, height: dotSize)
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
            Haptics.shared.prepareAll()
        }
        .onDisappear {
            // Clean up all timers and haptics
            for i in 0..<3 {
                stopInflating(dotIndex: i)
            }
        }
    }
    
    private func colorForDot(_ index: Int) -> Color {
        return .gray
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
        
        // Big pop pulse - heavy impact + bubble pop haptic
        Haptics.shared.impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            Haptics.shared.bubblePopHaptic()
        }
        
        // Make balloon disappear
        withAnimation(.easeOut(duration: 0.1)) {
            isVisible[dotIndex] = false
        }
        
        // Reset scale
        balloonScales[dotIndex] = 1.0
        
        // Reappear after ~1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isVisible[dotIndex] = true
            }
        }
    }
}

#Preview {
    ThreeDotGridView()
}