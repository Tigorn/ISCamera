//
//  ExposureView.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 22.10.2020.
//

import UIKit

class ExposureView: UIView {

    private var lightView: ExposureLightView?
    
    private var lineLayer: CAShapeLayer?
    private(set) var maskLayer: CAShapeLayer?

    private(set) var lightYConstraint: NSLayoutConstraint?
    
    private var lineStartPoint: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.minY)
    }
    
    private var lineEndPoint: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.maxY)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if lineLayer == nil, lightView == nil {
            configureViews()
            configureLightConstraints()
        }
    }
    
    private func configureViews() {
        let linePath: UIBezierPath = {
            let i = UIBezierPath()
            i.move(to: lineStartPoint)
            i.addLine(to: lineEndPoint)
            i.lineWidth = 2
            return i
        }()
        
        lineLayer = {
            let i = CAShapeLayer()
            i.path = linePath.cgPath
            i.strokeColor = UIColor(red: 244/255, green: 222/255, blue: 89/255, alpha: 1).cgColor
            i.lineCap = .round
            i.opacity = 0
            return i
        }()
        
        lightView = {
            let i = ExposureLightView()
            return i
        }()
        
        maskLayer = {
            let i = CAShapeLayer()
            i.path = maskPath()
            i.fillRule = .evenOdd
            return i
        }()
        
        addSubview(lightView!)
        layer.addSublayer(lineLayer!)
        
        lineLayer?.mask = maskLayer
    }

    private func configureConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 15).isActive = true
    }
    
    private func configureLightConstraints() {
        lightView?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        lightYConstraint = lightView?.centerYAnchor.constraint(equalTo: topAnchor, constant: frame.height / 2)
        lightYConstraint?.isActive = true
    }
    
    func setExposureY(factor: Float) {
        let height = frame.height * CGFloat(factor)
        lightYConstraint?.constant = height
        maskLayer?.path = maskPath(factor: factor)
        lineLayer?.opacity = 1
    }
    
    private func maskPath(factor: Float = 0.5) -> CGMutablePath {
        let i = CGMutablePath()
        let mask = maskRect(factor: factor)
        i.addRect(bounds)
        i.addRect(mask)
        return i
    }
    
    private func maskRect(factor: Float = 0.5) -> CGRect {
        let heightOffset = frame.height * CGFloat(factor)
        let origin = CGPoint(x: bounds.midX - 18, y: heightOffset - 18)
        let size = CGSize(width: 36, height: 36)
        return CGRect(origin: origin, size: size)
    }
    
}
