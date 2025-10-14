//
//  SoundManager.swift
//  Cravr Fidgetable Demo
//
//  Created by Ezra Akresh on 10/14/25.
//

import AVFoundation
import UIKit

class SoundManager {
    static let shared = SoundManager()
    
    private var audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var mixer: AVAudioMixerNode
    
    private init() {
        // Configure audio session first
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixer = audioEngine.mainMixerNode
        
        audioEngine.attach(playerNode)
        
        // Connect with explicit format
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        audioEngine.connect(playerNode, to: mixer, format: format)
        
        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Audio Control
    
    func stopAllSounds() {
        playerNode.stop()
        playerNode.play()
    }
    
    // MARK: - Sound Effects
    
    func playClick() {
        playTone(frequency: 800, duration: 0.05, volume: 0.3)
    }
    
    func playPop() {
        playTone(frequency: 600, duration: 0.08, volume: 0.3, pitchBend: -400)
    }
    
    func playDing() {
        playTone(frequency: 1200, duration: 0.15, volume: 0.25)
    }
    
    func playBubble() {
        playTone(frequency: 400, duration: 0.12, volume: 0.3, pitchBend: 300)
    }
    
    func playSwoosh() {
        playNoise(duration: 0.1, volume: 0.15)
    }
    
    func playChime() {
        playMultiTone(frequencies: [800, 1000, 1200], duration: 0.2, volume: 0.2)
    }
    
    // MARK: - Sound Generation
    
    private func playTone(frequency: Double, duration: Double, volume: Float, pitchBend: Double = 0) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        guard let samples = buffer.floatChannelData?[0] else { return }
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = Double(frame) / Double(frameCount)
            
            // Calculate frequency with pitch bend
            let currentFreq = frequency + (pitchBend * progress)
            
            // Generate sine wave
            let signal = sin(2.0 * .pi * currentFreq * t)
            
            // Apply envelope (fade in and out)
            let envelope: Double
            if progress < 0.1 {
                envelope = progress / 0.1
            } else if progress > 0.7 {
                envelope = 1.0 - ((progress - 0.7) / 0.3)
            } else {
                envelope = 1.0
            }
            
            samples[frame] = Float(signal * envelope) * volume
        }
        
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
    
    private func playMultiTone(frequencies: [Double], duration: Double, volume: Float) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        guard let samples = buffer.floatChannelData?[0] else { return }
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = Double(frame) / Double(frameCount)
            
            var signal = 0.0
            for frequency in frequencies {
                signal += sin(2.0 * .pi * frequency * t) / Double(frequencies.count)
            }
            
            // Apply envelope
            let envelope: Double
            if progress < 0.1 {
                envelope = progress / 0.1
            } else if progress > 0.6 {
                envelope = 1.0 - ((progress - 0.6) / 0.4)
            } else {
                envelope = 1.0
            }
            
            samples[frame] = Float(signal * envelope) * volume
        }
        
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
    
    private func playNoise(duration: Double, volume: Float) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        
        guard let samples = buffer.floatChannelData?[0] else { return }
        
        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(frameCount)
            
            // Generate filtered noise
            let noise = Float.random(in: -1...1)
            
            // Apply envelope
            let envelope = Float(1.0 - progress)
            
            samples[frame] = noise * envelope * volume
        }
        
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
}

