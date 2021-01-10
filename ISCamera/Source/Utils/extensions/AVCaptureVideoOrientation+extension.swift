//
//  AVCaptureVideoOrientation+extension.swift
//  ISCamera
//
//  Created by Igor Sorokin on 10.01.2021.
//

import AVFoundation
import UIKit

extension AVCaptureVideoOrientation {
    
    public init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        case .portraitUpsideDown: self = .portraitUpsideDown
        default: return nil
        }
    }
    
    static var deviceOrientation: AVCaptureVideoOrientation {
        let deviceOrientation = UIDevice.current.orientation
        let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation)
        return videoOrientation ?? .portrait
    }
    
}
