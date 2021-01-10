//
//  CGImage+extension.swift
//  ISCamera
//
//  Created by Igor Sorokin on 09.01.2021.
//

import UIKit

extension CGImage {
    
    func getPixelBuffer() -> CVPixelBuffer? {
        let context = CIContext()
        let ciimage = CIImage(cgImage: self)
        let size = CGSize(width: width, height: height)
        let pixelBuffer = CVPixelBuffer.allocCGPixelBuffer(size: size)!
        
        context.render(ciimage, to: pixelBuffer)
        
        return pixelBuffer
    }
    
}
