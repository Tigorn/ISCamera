//
//  AudioDevice.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 08.11.2020.
//

import AVFoundation

class ISAudioDevice {
    
    var input: AVCaptureDeviceInput?
    
    func authorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    func setupAudioInput(for session: AVCaptureSession, captureDevice: AVCaptureDevice) throws {
        do {
            let aInput = try AVCaptureDeviceInput(device: captureDevice)
            
            if session.canAddInput(aInput) {
                session.addInput(aInput)
                input = aInput
            }
            
        } catch {
            throw error
        }
    }
}
