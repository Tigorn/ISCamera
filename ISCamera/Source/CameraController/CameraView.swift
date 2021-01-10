//
//  CameraView.swift
//  ISCamera
//
//  Created by Igor Sorokin on 03.01.2021.
//

import UIKit

class CameraView: UIView {
    
    var settingsControl: ISSettingsControl!
    var captureControl: ISCaptureControl!
    var previewView: ISPreviewView!
    var tintLabel: UILabel!
    
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
    
    private func configureViews() {
        
        previewView = ISPreviewView(frame: UIScreen.main.bounds)
        captureControl = ISCaptureControl()
        settingsControl = ISSettingsControl()
        
        tintLabel = {
            let i = UILabel()
            i.textColor = .white
            i.font = .systemFont(ofSize: 14, weight: .semibold)
            i.text = "Удерживайте для записи видео"
            return i
        }()
        
        addSubview(previewView)
        addSubview(settingsControl)
        
        previewView.addSubview(captureControl)
        previewView.addSubview(tintLabel)
    }
    
    private func configureConstraints() {
        
        settingsControl.translatesAutoresizingMaskIntoConstraints = false
        captureControl.translatesAutoresizingMaskIntoConstraints = false
        tintLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            settingsControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            settingsControl.topAnchor.constraint(equalTo: topAnchor),
            settingsControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            captureControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            captureControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -60),
            captureControl.widthAnchor.constraint(equalToConstant: 67),
            captureControl.heightAnchor.constraint(equalToConstant: 67),
            
            tintLabel.topAnchor.constraint(equalTo: captureControl.bottomAnchor, constant: 18),
            tintLabel.centerXAnchor.constraint(equalTo: captureControl.centerXAnchor),
        ])
    }
    
}
