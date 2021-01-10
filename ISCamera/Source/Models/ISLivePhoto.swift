//
//  ISLivePhoto.swift
//  ISCamera
//
//  Created by Igor Sorokin on 07.01.2021.
//

import Foundation

class ISLivePhoto {
    let url: URL
    let width: Int32
    let height: Int32
    let duration: Double
    
    init(
        url: URL,
        width: Int32,
        height: Int32,
        duration: Double
    ) {
        self.url = url
        self.width = width
        self.height = height
        self.duration = duration
    }
    
}
