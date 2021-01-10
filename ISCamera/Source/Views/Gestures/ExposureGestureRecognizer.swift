//
//  ExposureGestureRecognizer.swift
//  ISCamera
//
//  Created by Igor Sorokin on 06.01.2021.
//

import UIKit.UIGestureRecognizer

class ExposureGestureRecognizer: UIPanGestureRecognizer {
    
    var translationRatio: Float = 0
    var exposure: Float = 0
    
    var controlSize: CGSize = .zero
    var minExposure: Float = 0
    var maxExposure: Float = 0
    
    private var currentYTranslation: CGFloat = 0
    private var incrementFactor: CGFloat = 0
    
    func configure(controlSize: CGSize, minExposure: Float, maxExposure: Float) {
        self.controlSize = controlSize
        self.minExposure = minExposure
        self.maxExposure = maxExposure
    }
    
    func resetExposure() {
        currentYTranslation = 0
        incrementFactor = 0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        incrementFactor = 0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        let gestTranslation = translation(in: view).y
        let increment = gestTranslation - incrementFactor
        incrementFactor = gestTranslation
        currentYTranslation += increment
        
        let yTranslation = currentYTranslation
        let translationFactor = Float(yTranslation / controlSize.height)
        let exposure = max(minExposure, min(translationFactor, maxExposure))
        let max = abs(maxExposure) + abs(minExposure)
        let exp = exposure + abs(minExposure)
        
        translationRatio = exp / max
        self.exposure = -1 * exposure
    }

}
