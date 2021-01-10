//
//  ISPhoto.swift
//  ISCamera
//
//  Created by Igor Sorokin on 07.01.2021.
//

import AVFoundation
import CoreImage

class ISPhoto {
    let image: CIImage
    let isRaw: Bool
    let type: AVFileType
    let width: Int32
    let height: Int32
    let created: Date
    var livePhoto: ISLivePhoto?
    
    init(
        image: CIImage,
        isRaw: Bool,
        type: AVFileType,
        width: Int32,
        height: Int32,
        created: Date = Date(),
        livePhoto: ISLivePhoto?
    ) {
        self.image = image
        self.isRaw = isRaw
        self.type = type
        self.width = width
        self.height = height
        self.created = created
        self.livePhoto = livePhoto
    }
    
}
