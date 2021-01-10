//
//  FourCharCode+extension.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 13.12.2020.
//

import Foundation

extension FourCharCode {
    
    func toString() -> String? {
        let cString: [CChar] = [
            CChar(self >> 24 & 0xFF),
            CChar(self >> 16 & 0xFF),
            CChar(self >> 8 & 0xFF),
            CChar(self & 0xFF),
            0
        ]
        return String(cString: cString)
    }
    
}
