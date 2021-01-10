//
//  VideoDevice.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 08.11.2020.
//

import AVFoundation

class ISVideoDevice {
    
    var input: AVCaptureDeviceInput?
    
    private let pressureStateKey: String = "pressureStateKVO"
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
            
            if let videoInput = input {
                session.removeInput(videoInput)
                
                if session.canAddInput(newVideoInput) {
                    session.addInput(newVideoInput)
                    input = newVideoInput
                } else {
                    session.addInput(videoInput)
                }
            }
            
        } catch {
            throw error
        }
    }
    
    func tourch(_ tourch: AVCaptureDevice.TorchMode) throws {
        try tryAction { (device) in
            if device.isTorchModeSupported(tourch) {
                device.torchMode = tourch
            }
        }
    }
    
    // MARK: - Zoom
    func zoom(factor: CGFloat) throws {
        try tryAction { (device) in
            let zoom = availableZoom(for: factor, in: device)
            device.videoZoomFactor = zoom
        }
    }
    
    func rampZoom(factor: CGFloat, rate: Float) throws {
        try tryAction { (device) in
            let zoom = availableZoom(for: factor, in: device)
            device.ramp(toVideoZoomFactor: zoom, withRate: rate)
        }
    }
    
    func cancelRampZoon() throws {
        try tryAction { (device) in
            device.cancelVideoZoomRamp()
        }
    }
    
    private func availableZoom(for factor: CGFloat, in device: AVCaptureDevice) -> CGFloat {
        return max(device.minAvailableVideoZoomFactor, min(factor, device.maxAvailableVideoZoomFactor))
    }

    // MARK: - Focus
    func focus(focusMode: AVCaptureDevice.FocusMode, at pointOfInterest: CGPoint) throws {
        try tryAction { (device) in
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = pointOfInterest
            }
            if device.isFocusModeSupported(focusMode) {
                device.focusMode = focusMode
            }
        }
    }
    
    func lockFocus(atLens position: Float, completion: ((CMTime) -> Void)? = nil) throws {
        try tryAction { (device) in
            if device.isLockingFocusWithCustomLensPositionSupported {
                device.setFocusModeLocked(lensPosition: position, completionHandler: completion)
            }
        }
    }
    
    func autofocus(rangeRestriction: AVCaptureDevice.AutoFocusRangeRestriction) throws {
        try tryAction { (device) in
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = rangeRestriction
            }
        }
    }
    
    func smoothAutoFocus(enable: Bool) throws {
        try tryAction { (device) in
            if device.isSmoothAutoFocusSupported {
                device.isSmoothAutoFocusEnabled = enable
            }
        }
    }
    
    // MARK: - Exposure
    func exposure(exposureMode: AVCaptureDevice.ExposureMode, at pointOfInterest: CGPoint) throws {
        try tryAction { (device) in
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = pointOfInterest
            }
            if device.isExposureModeSupported(exposureMode) {
                device.exposureMode = exposureMode
            }
        }
    }
    
    func exposure(exposureMode: AVCaptureDevice.ExposureMode, targetBias: Float) throws {
        try tryAction { (device) in
            if device.isExposureModeSupported(exposureMode) {
                device.exposureMode = exposureMode
            }
            
            let bias = max(device.minExposureTargetBias, min(targetBias, device.maxExposureTargetBias))
            device.setExposureTargetBias(bias)
        }
    }
    
    func exposure(duration: CMTime, iso: Float, completion: ((CMTime) -> Void)? = nil) throws {
        try tryAction { (device) in
            let minDuration = device.activeFormat.minExposureDuration
            let maxDuration = device.activeFormat.maxExposureDuration
            let rDuration = max(minDuration, min(duration, maxDuration))
            
            let minISO = device.activeFormat.minISO
            let maxISO = device.activeFormat.maxISO
            let rISO = max(minISO, min(iso, maxISO))
            
            device.setExposureModeCustom(duration: rDuration, iso: rISO, completionHandler: completion)
        }
    }
    
    // MARK: Subject area monitoring
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
        try? focus(focusMode: .continuousAutoFocus, at: devicePoint)
        try? exposure(exposureMode: .continuousAutoExposure, at: devicePoint)
    }
    
    // MARK: Configuration
    func setupVideoInput(for session: AVCaptureSession, captureDevice: AVCaptureDevice) throws {
        do {
            let vInput = try AVCaptureDeviceInput(device: captureDevice)
            
            if session.canAddInput(vInput) {
                session.addInput(vInput)
                input = vInput
            }
            
        } catch {
            throw error
        }
    }
    
    @available (iOS 11.1, *)
    func criticalPressureState(handle: Bool) {
        handle ? addPressureStateObserver() : removePressureStateObserver()
    }
    
    @available (iOS 11.1, *)
    private func addPressureStateObserver() {
        let pressureStateKVO = input?.device.observe(\.systemPressureState, options: .new) { [weak self] _, change in
            guard let pressureState = change.newValue else { return }
            self?.setRecommendedFrameRateRangeForPressureState(pressureState: pressureState)
        }
        
        keyValueObservations[pressureStateKey] = pressureStateKVO
    }
    
    private func removePressureStateObserver() {
        let kvo = keyValueObservations[pressureStateKey]
        kvo?.invalidate()
        keyValueObservations.removeValue(forKey: pressureStateKey)
    }
    
    @available (iOS 11.1, *)
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
    
    func tryAction(_ action: (AVCaptureDevice) -> Void) throws {
        guard let device = input?.device else { return }
        
        do {
            try device.lockForConfiguration()
            action(device)
            device.unlockForConfiguration()
        } catch {
            throw error
        }
    }
    
}
