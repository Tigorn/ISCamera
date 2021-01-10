//
//  ISVideoRecorderDelegate.swift
//  ISCamera
//
//  Created by Igor Sorokin on 10.01.2021.
//

import Foundation

protocol ISVideoRecorderDelegate: class {
    func videoRecorderStartRecording(_ recorder: ISVideoRecorder)
    func videoRecorderDidFail(_ recorder: ISVideoRecorder, with error: Error)
    func videoRecorderDidFinishRecording(_ recorder: ISVideoRecorder, video: ISVideo)
}
