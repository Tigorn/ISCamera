//
//  SepiaFilter.swift
//  ISCamera
//
//  Created by Igor Sorokin on 13.12.2020.
//

import CoreImage
import AVFoundation

class ISSepiaFilter: ISFilter, ISBufferAllocator {
    
    var isPrepared = false
    var outputFormatDescription: CMFormatDescription?
    
    private var ciContext: CIContext?
    private var rosyFilter: CIFilter?
    private var outputColorSpace: CGColorSpace?
    private var outputPixelBufferPool: CVPixelBufferPool?
    private(set) var inputFormatDescription: CMFormatDescription?
    
    func prepare(with formatDescription: CMFormatDescription, retainedBufferCountHint: Int) {
        reset()
        
        (outputPixelBufferPool, outputColorSpace, outputFormatDescription) = allocateOutputBufferPool(
            with: formatDescription,
            outputRetainedBufferCountHint: retainedBufferCountHint
        )
        
        if outputPixelBufferPool == nil {
            return
        }
        
        inputFormatDescription = formatDescription
        ciContext = CIContext(options: [.cacheIntermediates: false])
        rosyFilter = CIFilter(name: "CISepiaTone")
        isPrepared = true
    }
    
    func reset() {
        if let pbPool = outputPixelBufferPool {
            CVPixelBufferPoolFlush(pbPool, .excessBuffers)
        }
        
        ciContext = nil
        rosyFilter = nil
        outputColorSpace = nil
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        isPrepared = false
    }
    
    func process(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let rosyFilter = rosyFilter,
            let ciContext = ciContext,
            isPrepared else {
                assertionFailure("Invalid state: Not prepared")
                return nil
        }
        
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        rosyFilter.setValue(sourceImage, forKey: kCIInputImageKey)
        
        guard let filteredImage = rosyFilter.value(forKey: kCIOutputImageKey) as? CIImage else {
            print("CIFilter failed to render image")
            return nil
        }
        
        var pbuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &pbuf)
        guard let outputPixelBuffer = pbuf else {
            print("Allocation failure")
            return nil
        }
        
        // Render the filtered image out to a pixel buffer (no locking needed, as CIContext's render method will do that)
        ciContext.render(filteredImage, to: outputPixelBuffer, bounds: filteredImage.extent, colorSpace: outputColorSpace)
        return outputPixelBuffer
    }
    
}
