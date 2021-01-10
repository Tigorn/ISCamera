//
//  ISPhotoProcessor.swift
//  ISCamera
//
//  Created by Igor Sorokin on 07.01.2021.
//

import AVFoundation
import CoreImage

class ISStillPhotoProcessor: NSObject, ISPhotoProcessor {
    
    weak var filter: ISFilter?
    weak var delegate: ISPhotoProcessorDelegate?
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        delegate?.photoProcessor(self, willCapturePhotoFor: resolvedSettings)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        delegate?.photoProcessor(self, didCapturePhotoFor: resolvedSettings)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        let cgimage = photo.cgImageRepresentation()?.takeUnretainedValue()
        let previewCGimage = photo.previewCGImageRepresentation()?.takeUnretainedValue()
        
        guard
            var pixelBuffer = photo.pixelBuffer ??
                photo.previewPixelBuffer ??
                cgimage?.getPixelBuffer() ??
                previewCGimage?.getPixelBuffer() else {
            
            delegate?.photoProcessor(self, didFinishProcessingPhoto: nil, error: error)
            return
        }
        
        if
            let filter = filter,
            filter.isPrepared,
            let processedPixelBuffer = filter.process(pixelBuffer: pixelBuffer) {
            
            pixelBuffer = processedPixelBuffer
        }
        
        let width = Int32(CVPixelBufferGetWidth(pixelBuffer))
        let height = Int32(CVPixelBufferGetHeight(pixelBuffer))
        
        let orientationMetadata = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32
        let orientation = CGImagePropertyOrientation(rawValue: orientationMetadata ?? 6)
        let image = CIImage(cvImageBuffer: pixelBuffer).oriented(orientation ?? .right)
        
        let isPhoto = ISPhoto(
            image: image,
            isRaw: photo.isRawPhoto,
            type: .jpg,
            width: width,
            height: height,
            livePhoto: nil)
        
        delegate?.photoProcessor(self, didFinishProcessingPhoto: isPhoto, error: error)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        delegate?.photoProcessor(self, didFinishCaptureFor: resolvedSettings, error: error)
    }
    
}
