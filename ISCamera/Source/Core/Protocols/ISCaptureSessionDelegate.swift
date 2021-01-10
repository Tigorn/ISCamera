//
//  ISCaptureSessionDelegate.swift
//  ISCamera
//
//  Created by Igor Sorokin on 07.01.2021.
//

import AVFoundation

protocol ISCaptureSessionDelegate: class {
    func cameraManagerDidChangeStatus(_ sessionRunning: Bool)
    func cameraManagerSessionWasInterrupted(with reason: AVCaptureSession.InterruptionReason)
    func cameraManagerSessionInterruptionEnded()
    func cameraManagerRuntimeError(_ error: AVError)
}
