//
//  ISCaptureButton.swift
//  ISCamera
//
//  Created by Igor Sorokin on 01.01.2021.
//

import UIKit
import AudioToolbox

class ISCaptureControl: UIControl {
    
    enum Mode {
        case photo
        case video
        
        var isVideo: Bool {
            self == .video
        }
        
        func toggle() -> Mode {
            return isVideo ? .photo : .video
        }
    }
    
    var mode: Mode = .photo
    var photoTapped: ((ISCaptureControl) -> Void)?
    var videoTapped: ((ISCaptureControl) -> Void)?
    
    var mainColor: UIColor = .white
    var disableColor: UIColor = .lightGray
    var highlightedColor: UIColor = .lightGray
    var recordingColor: UIColor = .red
    
    override var isEnabled: Bool {
        didSet {
            outlineLayer?.borderColor = isEnabled ? mainColor.cgColor : disableColor.cgColor
            circleLayer?.backgroundColor = isEnabled ? mainColor.cgColor : disableColor.cgColor
            setNeedsDisplay()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            outlineLayer?.borderColor = isHighlighted ? highlightedColor.cgColor : mainColor.cgColor
            circleLayer?.backgroundColor = isHighlighted ? highlightedColor.cgColor : mainColor.cgColor
            setNeedsDisplay()
        }
    }
    
    var outlineLayer: CALayer?
    var circleLayer: CALayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureGestures()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard
            outlineLayer == nil,
            circleLayer == nil else { return }
        
        configureLayers()
    }
    
    func configureGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(captureTapped(_:)))
        let longtapGesture = UILongPressGestureRecognizer(target: self, action: #selector(captureLongtapped(_:)))
        
        longtapGesture.minimumPressDuration = 0.1
        longtapGesture.require(toFail: tapGesture)
        
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(longtapGesture)
    }
    
    @objc func captureTapped(_ sender: UITapGestureRecognizer) {
        if mode.isVideo {
            animate(to: .photo)
            mode = mode.toggle()
            videoTapped?(self)
        } else {
            photoTapped?(self)
        }
    }
    
    @objc func captureLongtapped(_ sender: UITapGestureRecognizer) {
        guard sender.state == .began else { return }
        
        if mode.isVideo {
            animate(to: .photo)
        } else {
            vibrate()
            animate(to: .video)
        }
        
        mode = mode.toggle()
        videoTapped?(self)
    }
    
    func animate(to state: Mode) {
        
        if !state.isVideo {
            circleLayer?.removeAnimation(forKey: "to-video")
        }
        
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        let outlineD = outlineLayer?.frame.width ?? 0
        let circleD = circleLayer?.frame.width ?? 0
        let ratio = outlineD / circleD
        scaleAnimation.values = [1, 0.8, ratio, 0.8, 1]
        scaleAnimation.keyTimes = [0, 0.2, 0.6, 0.8, 1]
        
        let bgAnimation = CABasicAnimation(keyPath: "backgroundColor")
        bgAnimation.toValue = state.isVideo ? recordingColor.cgColor : mainColor.cgColor
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.duration = state.isVideo ? 0.65 : 0.15
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        groupAnimation.animations = state.isVideo ? [scaleAnimation, bgAnimation] : [bgAnimation]
        groupAnimation.fillMode = .forwards
        groupAnimation.isRemovedOnCompletion = false
        
        circleLayer?.add(groupAnimation, forKey: state.isVideo ? "to-video" : "to-photo")
    }
    
    func vibrate() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func configureLayers() {
        outlineLayer = {
            let i = CALayer()
            i.frame = bounds
            i.cornerRadius = bounds.height / 2
            i.backgroundColor = UIColor.clear.cgColor
            i.borderColor = mainColor.cgColor
            i.borderWidth = 4
            return i
        }()
        
        circleLayer = {
            let i = CALayer()
            let compressedRect = bounds.inset(by: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
            i.frame = compressedRect
            i.cornerRadius = compressedRect.height / 2
            i.backgroundColor = mainColor.cgColor
            return i
        }()
        
        layer.addSublayer(outlineLayer!)
        layer.addSublayer(circleLayer!)
    }
    
}
