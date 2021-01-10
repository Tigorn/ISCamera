//
//  Video.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 13.12.2020.
//

import AVFoundation

class ISVideo {
    let url: URL
    let type: AVFileType
    let codec: String?
    let width: Int32
    let height: Int32
    let created: Date
    var duration: Double?
    
    init(
        url: URL,
        type: AVFileType,
        codec: String?,
        width: Int32,
        height: Int32,
        created: Date = Date(),
        duration: Double?
    ) {
        self.url = url
        self.type = type
        self.codec = codec
        self.width = width
        self.height = height
        self.created = created
        self.duration = duration
    }
}
