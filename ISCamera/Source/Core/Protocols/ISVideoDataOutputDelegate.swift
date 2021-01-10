//
//  ISVideoDataOutputDelegate.swift
//  ISCamera
//
//  Created by Igor Sorokin on 07.01.2021.
//

import Foundation

protocol ISVideoDataOutputDelegate: class {
    func videoCaptureStartRecording()
    func videoCaptureDidFinishRecording(video: ISVideo)
    func videoCaptureDidFail(with error: Error)
}

extension ISVideoDataOutputDelegate {
    func videoCaptureStartRecording() { }
    func videoCaptureDidFail(with error: Error) { }
}
