//
//  ISFilter.swift
//  ISCamera
//
//  Created by Igor Sorokin on 19.12.2020.
//

import AVFoundation

protocol ISFilter: class {
    var isPrepared: Bool { get }
    var outputFormatDescription: CMFormatDescription? { get }
    
    func prepare(with formatDescription: CMFormatDescription, retainedBufferCountHint: Int)
    func process(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
}
