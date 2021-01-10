//
//  ISPhotoOutputDelegate.swift
//  ISCamera
//
//  Created by Igor Sorokin on 07.01.2021.
//

import AVFoundation

protocol ISPhotoProcessorDelegate: class {
    func photoProcessor(_ processor: ISPhotoProcessor, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings)
    func photoProcessor(_ processor: ISPhotoProcessor, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings)
    func photoProcessor(_ processor: ISPhotoProcessor, didFinishProcessingPhoto photo: ISPhoto?, error: Error?)
    func photoProcessor(_ processor: ISPhotoProcessor, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?)
}

extension ISPhotoProcessorDelegate {
    func photoProcessor(_ processor: ISPhotoProcessor, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) { }
    func photoProcessor(_ processor: ISPhotoProcessor, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) { }
    func photoProcessor(_ processor: ISPhotoProcessor, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) { }
}
