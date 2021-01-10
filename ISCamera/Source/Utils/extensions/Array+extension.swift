//
//  Array+extension.swift
//  ISCamera
//
//  Created by Igor Sorokin on 10.01.2021.
//

import AVFoundation

extension Array where Element == Float {
    
    static func textureVerticies(for orientation: AVCaptureVideoOrientation) -> [Float] {
        switch orientation {
        case .landscapeRight:
            return [
                0.0, 1.0,
                1.0, 1.0,
                0.0, 0.0,
                1.0, 0.0
            ]
            
        case .landscapeLeft:
            return [
                1.0, 0.0,
                0.0, 0.0,
                1.0, 1.0,
                0.0, 1.0
            ]

        case .portraitUpsideDown:
            return [
                0.0, 0.0,
                0.0, 1.0,
                1.0, 0.0,
                1.0, 1.0
            ]
            
        default: // portrait
            return [
                1.0, 1.0,
                1.0, 0.0,
                0.0, 1.0,
                0.0, 0.0
            ]
        }
    }
    
}
