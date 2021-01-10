//
//  UIImage+extension.swift
//  ISCamera
//
//  Created by Igor Sorokin on 10.01.2021.
//

import UIKit

extension UIImage {
    
    static var orientationFromDevice: UIImage.Orientation {
        switch UIDevice.current.orientation {
        case .landscapeRight:
            return .down
        case .landscapeLeft:
            return .up
        case .portraitUpsideDown:
            return .left
        default:
            return .right
        }
    }
    
    static func transformForOrientation(orientation: UIImage.Orientation) -> CGAffineTransform {
        switch orientation {
        case .right:
            return CGAffineTransform.identity.rotated(by: -.pi / 2)
        case .down:
            return CGAffineTransform.identity.rotated(by: .pi)
        case .left:
            return CGAffineTransform.identity.rotated(by: .pi / 2)
        default:
            return .identity
        }
    }

}
