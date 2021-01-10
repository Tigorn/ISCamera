//
//  ISPhotoProcessor.swift
//  ISCamera
//
//  Created by Igor Sorokin on 10.01.2021.
//

import AVFoundation

protocol ISPhotoProcessor: AVCapturePhotoCaptureDelegate {
    var filter: ISFilter? { get set }
    var delegate: ISPhotoProcessorDelegate? { get set }
}
