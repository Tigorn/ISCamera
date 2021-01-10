//
//  CameraManager.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 15.11.2020.
//

import UIKit
import AVFoundation

class ISCameraManager {
    
    var videoDevice: ISVideoDevice = .init()
    var audioDevice: ISAudioDevice = .init()
    
    var photoOutput: ISPhotoOutput = .init()
    var videoOutput: ISVideoDataOutput = .init()
    
    var session: ISCaptureSession = .init()
    
    var previewView: ISRenderer? {
        set {
            videoOutput.renderer = newValue
        }
        get {
            videoOutput.renderer
        }
    }
    
    var filter: ISFilter? {
        set {
            videoOutput.filter = newValue
        }
        get {
            videoOutput.filter
        }
    }
    
    var isFlashAvailable: Bool {
        videoDevice.input?.device.isFlashAvailable ?? false
    }
    
    var isTorchAvailable: Bool {
        videoDevice.input?.device.isTorchAvailable ?? false
    }
    
    var deviceOrientation: UIDeviceOrientation {
        UIDevice.current.orientation
    }
    
    var maxExposure: Float {
        videoDevice.input?.device.maxExposureTargetBias ?? 0
    }
    
    var minExposure: Float {
        videoDevice.input?.device.minExposureTargetBias ?? 0
    }
    
    var minExposireDuration: CMTime {
        videoDevice.input?.device.activeFormat.minExposureDuration ?? .zero
    }
    
    var maxExposireDuration: CMTime {
        videoDevice.input?.device.activeFormat.maxExposureDuration ?? .zero
    }
    
    var minISO: Float {
        videoDevice.input?.device.activeFormat.minISO ?? .zero
    }
    
    var maxISO: Float {
        videoDevice.input?.device.activeFormat.maxISO ?? .zero
    }
    
    var maxZoom: CGFloat {
        videoDevice.input?.device.maxAvailableVideoZoomFactor ?? 0
    }
    
    var minZoom: CGFloat {
        videoDevice.input?.device.minAvailableVideoZoomFactor ?? 0
    }
    
    init(configurator: (ISCameraManager) -> Void) {
        configurator(self)
    }
    
    func capturePhoto(processor: AVCapturePhotoCaptureDelegate) {
        photoOutput.capture(processor: processor)
    }
    
    func startRecording(to url: URL) {
        videoOutput.startRecording(to: url)
    }
    
    func stopRecording() {
        videoOutput.stopRecording()
    }
    
    func changeVideoDevice(
        _ device: AVCaptureDevice,
        updatePresetTo newPreset: AVCaptureSession.Preset? = nil,
        completion: ((Error?) -> Void)?
    ) {
        videoOutput.pauseRecording()
        
        session.configure(configuration: { [weak self] in
            guard let self = self else { return }
            
            if let preset = newPreset {
                self.session.sessionPreset = preset
            }
            
            try self.videoDevice.changeCamera(for: self.session, newCaptureDevice: device)
            self.videoOutput.changeCameraConnection(for: self.session)
            
        }, completion: { [weak self] in
            guard let self = self else { return }
            
            if device.hasMediaType(.video) {
                self.previewView?.isMirroring = (device.position == .front)
            }
            
            self.videoOutput.resumeRecording()
            
            completion?($0)
        })
    }
    
    func startSession() {
        session.startRunning()
    }
    
    func stopSession() {
        session.stopRunning()
    }
    
    func resumeInterruptedSession() {
        session.resumeRunning()
    }
    
    // MARK: - Setup Devices
    func setupVideoDevice(_ device: AVCaptureDevice, completion: ((Error?) -> Void)? = nil) {
        session.configure(configuration: { [weak self] in
            guard let self = self else { return }
            try self.videoDevice.setupVideoInput(for: self.session, captureDevice: device)
            self.videoOutput.setupVideoOutput(for: self.session)
            self.photoOutput.setupOutput(for: self.session)
        }, completion: completion)
    }
    
    func setupAudioDevice(_ device: AVCaptureDevice, completion: ((Error?) -> Void)? = nil) {
        session.configure(configuration: { [weak self] in
            guard let self = self else { return }
            try self.audioDevice.setupAudioInput(for: self.session, captureDevice: device)
            self.videoOutput.setupAudioOutput(for: self.session)
        }, completion: completion)
    }
    
}

extension ISCameraManager {
    
    class func device(
        preferredType: AVCaptureDevice.DeviceType?,
        mediaType: AVMediaType,
        position: AVCaptureDevice.Position
    ) -> AVCaptureDevice? {
        
        var deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInDualCamera,
            .builtInTelephotoCamera,
            .builtInWideAngleCamera,
            .builtInMicrophone
        ]
        
        if #available(iOS 13.0, *) {
            deviceTypes.append(contentsOf: [.builtInDualWideCamera, .builtInUltraWideCamera, .builtInTripleCamera])
        }
        
        if #available(iOS 11.1, *) {
            deviceTypes.append(contentsOf: [.builtInTrueDepthCamera])
        }
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: mediaType, position: position)
        let devices = discoverySession.devices
        let preferredDevice = devices.first(where: { $0.deviceType == preferredType })
        let defaultDevice = devices.first
        let resultDevice = preferredDevice ?? defaultDevice
        
        return resultDevice
    }
    
}
