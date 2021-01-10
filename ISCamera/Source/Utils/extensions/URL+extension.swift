//
//  URL+extension.swift
//  ISCamera
//
//  Created by Igor Sorokin on 10.01.2021.
//

import Foundation

extension URL {

    static var generateVideoURl: URL {
        let outputFileName = NSUUID().uuidString
        let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
        return URL(fileURLWithPath: outputFilePath)
    }
    
}
