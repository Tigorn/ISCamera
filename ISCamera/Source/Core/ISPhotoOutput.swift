//
//  PhotoCaptureModule.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 08.11.2020.
//

import UIKit
import AVFoundation

class ISPhotoOutput: NSObject {
    
    var connection: AVCaptureConnection?
    let output: AVCapturePhotoOutput = .init()
    
    var photoSettings: ISPhotoSettings = .compressed(codec: .jpeg)
    var flashMode: AVCaptureDevice.FlashMode = .auto
    var highResolutionPhotoEnabled: Bool = false
    
//    var livePhotoModeEnable: Bool {
//        set { _livePhotoModeEnable = output.isLivePhotoCaptureSupported && newValue }
//        get { _livePhotoModeEnable && output.isLivePhotoCaptureSupported }
//    }
    
    var depthDataDeliveryModeEnable: Bool {
        set { _depthDataDeliveryModeEnable = output.isDepthDataDeliverySupported && newValue }
        get { _depthDataDeliveryModeEnable && output.isDepthDataDeliverySupported }
    }
    
    @available(iOS 12.0, *)
    var portraitEffectsMatteDeliveryModeEnable: Bool {
        set { _portraitEffectsMatteDeliveryModeEnable = output.isPortraitEffectsMatteDeliverySupported && newValue }
        get { _portraitEffectsMatteDeliveryModeEnable && output.isPortraitEffectsMatteDeliverySupported }
    }
    
    @available(iOS 12.0, *)
    var isAutoRedEyeReductionEnabled: Bool {
        set { _isAutoRedEyeReductionEnabled = output.isAutoRedEyeReductionSupported && newValue }
        get { _isAutoRedEyeReductionEnabled && output.isAutoRedEyeReductionSupported }
    }
    
    var isCameraCalibrationDataDeliveryEnabled: Bool {
        set { _isCameraCalibrationDataDeliveryEnabled = output.isCameraCalibrationDataDeliverySupported && newValue }
        get { _isCameraCalibrationDataDeliveryEnabled && output.isCameraCalibrationDataDeliverySupported }
    }
    
    private var _isAutoRedEyeReductionEnabled: Bool = false
    private var _livePhotoModeEnable: Bool = false
    private var _depthDataDeliveryModeEnable: Bool = false
    private var _portraitEffectsMatteDeliveryModeEnable: Bool = false
    private var _isCameraCalibrationDataDeliveryEnabled: Bool = false
    
    func setupOutput(for session: AVCaptureSession) {
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        connection = output.connection(with: .video)
    }
    
    func capture(processor: AVCapturePhotoCaptureDelegate) {
        
        let photoSettings = self.photoSettings.resolveCaptureSettings(for: output)
        
        photoSettings.flashMode = flashMode
        photoSettings.isHighResolutionPhotoEnabled = highResolutionPhotoEnabled
        photoSettings.isDepthDataDeliveryEnabled = depthDataDeliveryModeEnable
        photoSettings.isCameraCalibrationDataDeliveryEnabled = isCameraCalibrationDataDeliveryEnabled
        
        if #available(iOS 12.0, *) {
            photoSettings.isPortraitEffectsMatteDeliveryEnabled = portraitEffectsMatteDeliveryModeEnable
            photoSettings.isAutoRedEyeReductionEnabled = isAutoRedEyeReductionEnabled
        }
        
        output.capturePhoto(with: photoSettings, delegate: processor)
    }
    
}
