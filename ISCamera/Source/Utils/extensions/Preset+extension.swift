//
//  Preset+extension.swift
//  ISCamera
//
//  Created by Igor Sorokin on 06.01.2021.
//

import AVFoundation

extension AVCaptureSession {
    
    var maxAvailablePreset: AVCaptureSession.Preset {
        if canSetSessionPreset(.hd4K3840x2160) {
            return .hd4K3840x2160
        } else if canSetSessionPreset(.hd1920x1080) {
            return .hd1920x1080
        } else if canSetSessionPreset(.hd1280x720) {
            return .hd1280x720
        } else if canSetSessionPreset(.vga640x480) {
            return .vga640x480
        }
        
        return .cif352x288
    }
    
}
