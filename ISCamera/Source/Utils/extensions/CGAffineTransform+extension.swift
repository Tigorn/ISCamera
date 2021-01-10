//
//  CGAffineTransform+extension.swift
//  ISCamera
//
//  Created by Igor Sorokin on 10.01.2021.
//

import UIKit
import AVFoundation

extension CGAffineTransform {
    
    static func transform(for bufferOrientation: AVCaptureVideoOrientation) -> CGAffineTransform {
        let orientationAngleOffset = angleOffset(from: .deviceOrientation)
        let videoOrientationAngleOffset = angleOffset(from: bufferOrientation)
        let angleOffset = orientationAngleOffset - videoOrientationAngleOffset
        let transform = CGAffineTransform(rotationAngle: angleOffset)
        
        return transform
    }
    
    static func angleOffset(from orientation: AVCaptureVideoOrientation) -> CGFloat {
        var angle: CGFloat = 0
        
        switch orientation {
        case .portrait: angle = 0
        case .portraitUpsideDown: angle = .pi
        case .landscapeRight: angle = -(.pi / 2)
        case .landscapeLeft: angle = .pi / 2
        @unknown default: break
        }
        
        return angle
    }
    
}
