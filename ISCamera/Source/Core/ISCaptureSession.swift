//
//  ISCaptureSession.swift
//  ISCamera
//
//  Created by Igor Sorokin on 01.01.2021.
//

import AVFoundation

class ISCaptureSession: AVCaptureSession {
    
    weak var delegate: ISCaptureSessionDelegate?
    
    private var keyValueObservations: [NSKeyValueObservation] = []
    private let queue: DispatchQueue = .init(label: "iscamera.iscapturesession.queue")
    
    override func startRunning() {
        queue.async {
            super.startRunning()
            self.addObservers()
        }
    }
    
    override func stopRunning() {
        queue.async {
            NotificationCenter.default.removeObserver(self)
            self.keyValueObservations.forEach { $0.invalidate() }
            self.keyValueObservations.removeAll()
            
            super.stopRunning()
        }
    }
    
    func resumeRunning() {
        queue.async {
            super.startRunning()
        }
    }
    
    func configure(configuration: @escaping () throws -> Void, completion: ((Error?) -> Void)?) {
        queue.async {
            self.beginConfiguration()
            
            var configurationError: Error?
            
            do {
                try configuration()
            } catch {
                configurationError = error
            }
            
            self.commitConfiguration()
            DispatchQueue.main.async {
                completion?(configurationError)
            }
        }
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionRuntimeError),
            name: .AVCaptureSessionRuntimeError,
            object: self
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: .AVCaptureSessionWasInterrupted,
            object: self
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: .AVCaptureSessionInterruptionEnded,
            object: self
        )
        
        let isRunningKVO = self.observe(\.isRunning, options: .new) { [weak self] _, change in
            guard let isRunning = change.newValue else { return }

            DispatchQueue.main.async {
                self?.delegate?.cameraManagerDidChangeStatus(isRunning)
            }
        }
        
        keyValueObservations.append(isRunningKVO)
    }
    
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        delegate?.cameraManagerRuntimeError(error)
        
        if error.code == .mediaServicesWereReset {
            queue.async {
                self.resumeRunning()
            }
        }
    }
    
    @objc func sessionWasInterrupted(notification: NSNotification) {
        guard
            let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) else { return }
        
        delegate?.cameraManagerSessionWasInterrupted(with: reason)
    }
    
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        delegate?.cameraManagerSessionInterruptionEnded()
    }
    
}
