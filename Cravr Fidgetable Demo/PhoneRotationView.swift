//
//  PhoneRotationView.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/13/25.
//

import SwiftUI
import CoreMotion

struct PhoneRotationView: View {
    @State private var phoneRotation: Double = 0
    @State private var lastRotationIntensity: Float = 0
    @State private var rotationSpeed: Double = 0
    
    private let motionManager = CMMotionManager()
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Phone Rotation")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Rotate your phone to feel vibrations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThickMaterial)
                        .frame(width: 250, height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.black.opacity(0.1), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 20) {
                        Image(systemName: "iphone")
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)
                            .rotationEffect(.degrees(phoneRotation))
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: phoneRotation)
                        
                        Text("Rotation Speed: \(String(format: "%.1f", rotationSpeed))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                
                // Rotation intensity indicator
                VStack(spacing: 12) {
                    Text("Rotation Intensity")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(rotationSpeed > Double(index) * 0.2 ? Color.accentColor : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                                .animation(.easeInOut(duration: 0.2), value: rotationSpeed)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(40)
        }
        .onAppear {
            Haptics.shared.prepareAll()
            setupMotionManager()
        }
        .onDisappear {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    private func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }
            
            let attitude = motion.attitude
            let rotationRate = motion.rotationRate
            
            // Calculate rotation intensity based on rotation rate
            let intensity = sqrt(pow(rotationRate.x, 2) + pow(rotationRate.y, 2) + pow(rotationRate.z, 2))
            let normalizedIntensity = min(Float(intensity) / 3.0, 1.0)
            
            // Update phone rotation for visual feedback
            phoneRotation = attitude.roll * 180 / .pi
            
            // Update rotation speed for display
            rotationSpeed = Double(normalizedIntensity)
            
            // Haptic feedback based on rotation intensity
            if normalizedIntensity > 0.1 && abs(normalizedIntensity - lastRotationIntensity) > 0.05 {
                Haptics.shared.rotationTick(intensity: normalizedIntensity)
                lastRotationIntensity = normalizedIntensity
            }
        }
    }
}

#Preview {
    PhoneRotationView()
}
