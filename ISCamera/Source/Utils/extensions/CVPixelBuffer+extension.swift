//
//  CVPixelBuffer+extension.swift
//  ISCamera
//
//  Created by Igor Sorokin on 09.01.2021.
//

import AVFoundation

extension CVPixelBuffer {
    
    static func allocCGPixelBuffer(size: CGSize) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer : CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer)

        return pixelBuffer
    }
    
}
