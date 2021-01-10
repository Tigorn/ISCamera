//
//  ControlsView.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 22.10.2020.
//

import UIKit

class ControlsView: UIView {

    private(set) var focusView: FocusView!
    private(set) var exposureView: ExposureView!
    private var controlsWorkItem: DispatchWorkItem?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
        configureConstraints()
    }
    
    func setExposureY(factor: Float) {
        exposureView.setExposureY(factor: factor)
    }
    
    func remove() {
        invalidateControlsWorkitem()
        removeFromSuperview()
    }
    
    func invalidateControlsWorkitem() {
        controlsWorkItem?.cancel()
        controlsWorkItem = nil
    }
    
    func startControlsWorkitem() {
        controlsWorkItem = DispatchWorkItem { [weak self] in self?.remove() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: controlsWorkItem!)
    }
    
    private func configureViews() {
        alpha = 0.9
        
        focusView = {
            let i = FocusView()
            return i
        }()
        
        exposureView = {
            let i = ExposureView()
            return i
        }()
        
        addSubview(focusView)
        addSubview(exposureView)
    }
    
    private func configureConstraints() {
        focusView.translatesAutoresizingMaskIntoConstraints = false
        exposureView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            focusView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            focusView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            focusView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            exposureView.topAnchor.constraint(equalTo: topAnchor),
            exposureView.leadingAnchor.constraint(equalTo: focusView.trailingAnchor, constant: 8),
            exposureView.trailingAnchor.constraint(equalTo: trailingAnchor),
            exposureView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
}

extension ControlsView {
    class func showControls(on view: UIView, at point: CGPoint) -> ControlsView {
        let control: ControlsView = {
            let i = ControlsView(frame: .zero)
            i.frame.size = i.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            i.center = point
            i.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            return i
        }()
        
        view.addSubview(control)
        
        UIView.animate(withDuration: 0.2, animations: {
            control.transform = .identity
        }, completion: { (_) in
            control.startControlsWorkitem()
        })
        
        return control
    }
}
