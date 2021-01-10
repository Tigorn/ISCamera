//
//  LightMode.swift
//  ISCamera
//
//  Created by Igor Sorokin on 10.01.2021.
//

import AVFoundation
import UIKit

enum LightMode: Int {
    case auto
    case on
    case off
    
    var image: UIImage {
        switch self {
        case .auto: return UIImage(named: "flash-auto")!
        case .off:  return UIImage(named: "flash-off")!
        case .on:   return UIImage(named: "flash-on")!
        }
    }
    
    var torch: AVCaptureDevice.TorchMode {
        switch self {
        case .auto: return .auto
        case .off:  return .off
        case .on:   return .on
        }
    }
    
    var flash: AVCaptureDevice.FlashMode {
        switch self {
        case .auto: return .auto
        case .off:  return .off
        case .on:   return .on
        }
    }
    
    func nextMode() -> LightMode {
        let nextRawValue = rawValue + 1
        let normallyRawValue = nextRawValue % 3
        return LightMode(rawValue: normallyRawValue)!
    }
}
