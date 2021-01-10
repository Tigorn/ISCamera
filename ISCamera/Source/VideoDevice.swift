//
//  VideoDevice.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 08.11.2020.
//

import AVFoundation

class ISVideoDevice {
    
    var input: AVCaptureDeviceInput?
    
    private var keyValueObservations: [String: NSKeyValueObservation] = [:]
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        keyValueObservations.forEach { $0.value.invalidate() }
        keyValueObservations.removeAll()
    }
    
    func authorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func changeCamera(for session: AVCaptureSession, newCaptureDevice: AVCaptureDevice) throws {
        do {
            let newVideoInput = try AVCaptureDeviceInput(device: newCaptureDevice)
            
            session.beginConfiguration()
            
            if session.canAddInput(newVideoInput) {
                
                if let videoInput = input {
                    session.removeInput(videoInput)
                }
                
                session.addInput(newVideoInput)
                input = newVideoInput
            }
            
            session.commitConfiguration()
        } catch {
            throw error
        }
    }
    
    func focus(with focusMode: AVCaptureDevice.FocusMode, at devicePoint: CGPoint) throws {
        guard let device = input?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                device.focusPointOfInterest = devicePoint
                device.focusMode = focusMode
            }
            
            device.unlockForConfiguration()
        } catch {
            throw error
        }
    }
    
    func exposure(with exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint) throws {
        guard let device = input?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = exposureMode
            }
            
        } catch {
            throw error
        }
    }
    
    func setupVideoInput(for session: AVCaptureSession, captureDevice: AVCaptureDevice) throws {
        do {
            let vInput = try AVCaptureDeviceInput(device: captureDevice)
            
            if session.canAddInput(vInput) {
                session.addInput(vInput)
                input = vInput
            }
            
        } catch {
            print("BaseCameraManager warning: Couldn't create AVCaptureDeviceInput: \(error)")
            throw error
        }
    }
    
    func setSubjectAreaMonitoring(enable: Bool) throws {
        guard let device = input?.device else { return }
        
        setSubjectAreaDidChangeNotification(enable: enable)
        
        do {
            try device.lockForConfiguration()
            device.isSubjectAreaChangeMonitoringEnabled = enable
            device.unlockForConfiguration()
        } catch {
            throw error
        }
    }
    
    private func setSubjectAreaDidChangeNotification(enable: Bool) {
        if enable {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(subjectAreaDidChange),
                name: .AVCaptureDeviceSubjectAreaDidChange,
                object: input?.device)
        } else {
            NotificationCenter.default.removeObserver(
                self,
                name: .AVCaptureDeviceSubjectAreaDidChange,
                object: input?.device)
        }
    }
    
    @objc private func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        try? focus(with: .continuousAutoFocus, at: devicePoint)
        try? exposure(with: .continuousAutoExposure, at: devicePoint)
    }
    
    func criticalPressureState(handle: Bool) {
        handle ? addPressureStateObserver() : removePressureStateObserver()
    }
    
    private func addPressureStateObserver() {
        let pressureStateKVO = input?.device.observe(\.systemPressureState, options: .new) { [weak self] _, change in
            guard let pressureState = change.newValue else { return }
            self?.setRecommendedFrameRateRangeForPressureState(pressureState: pressureState)
        }
        
        keyValueObservations["pressureStateKVO"] = pressureStateKVO
    }
    
    private func removePressureStateObserver() {
        let kvo = keyValueObservations["pressureStateKVO"]
        kvo?.invalidate()
        keyValueObservations.removeValue(forKey: "pressureStateKVO")
    }
    
    private func setRecommendedFrameRateRangeForPressureState(pressureState: AVCaptureDevice.SystemPressureState) {
        let pressureLevel = pressureState.level
        
        print("ISVideoDevice reached elevated system pressure level: \(pressureLevel).")
        
        if pressureLevel == .serious || pressureLevel == .critical {
            try? input?.device.lockForConfiguration()
            input?.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
            input?.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
            input?.device.unlockForConfiguration()
        }
    }
    
}
