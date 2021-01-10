//
//  MediaManager.swift
//  ISCamera
//
//  Created by Igor Sorokin on 10.01.2021.
//

import Photos

class MediaManager {
    
    static func removeFile(at url: URL) {
        let path = url.path
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("Could not remove file at url: \(url)")
            }
        }
    }

    static func saveVideo(fileURl: URL, _ completion: ((Bool, Error?) -> Void)? = nil) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: fileURl)
                }, completionHandler: completion)
            }
        }
    }
    
    static func saveStillPhoto(_ photo: Data, withLivePhotoAt url: URL? = nil, completion: ((Bool, Error?) -> Void)? = nil) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    
                    creationRequest.addResource(with: .photo, data: photo, options: nil)
                    
                    if let url = url {
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        creationRequest.addResource(with: .pairedVideo, fileURL: url, options: options)
                    }
                    
                }, completionHandler: completion)
            }
        }
    }
    
}
