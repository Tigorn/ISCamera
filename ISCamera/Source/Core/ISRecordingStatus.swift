//
//  RecordingStatus.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 13.12.2020.
//

import Foundation

enum ISRecodingStatus: Int {
    case idle
    case prepared
    case recording
    case paused
    case finished
    case failed
    
    var isIdle: Bool {
        self == .idle
    }
    
    var isRecording: Bool {
        self == .recording
    }
    
    var isPrepared: Bool {
        self == .prepared
    }
    
    var isFinal: Bool {
        (self == .failed) || (self == .finished)
    }
    
    var recordingOrPrepared: Bool {
        (self == .recording) || (self == .prepared)
    }
    
    var isFaild: Bool {
        self == .failed
    }
    
    var isPaused: Bool {
        self == .paused
    }
}
