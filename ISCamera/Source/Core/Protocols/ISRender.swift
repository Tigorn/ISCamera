//
//  ISRender.swift
//  ISCamera
//
//  Created by Igor Sorokin on 07.01.2021.
//

import AVFoundation

protocol ISRenderer: class {
    var isMirroring: Bool { get set }
    func render(pixelBuffer: CVPixelBuffer)
}
