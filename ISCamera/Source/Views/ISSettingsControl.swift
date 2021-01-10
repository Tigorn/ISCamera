//
//  ISSettingsControl.swift
//  ISCamera
//
//  Created by Igor Sorokin on 03.01.2021.
//

import UIKit

class ISSettingsControl: UIView {
    
    var changeCamera: UIButton!
    var lightMode: UIButton!
    var stackView: UIStackView!
    
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
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        changeCamera = {
            let i = UIButton()
            i.setImage(UIImage(named: "change-camera"), for: .normal)
            return i
        }()
        
        lightMode = {
            let i = UIButton()
            return i
        }()
        
        stackView = {
            let i = UIStackView(arrangedSubviews: [lightMode, changeCamera])
            i.isLayoutMarginsRelativeArrangement = true
            i.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            i.axis = .horizontal
            i.spacing = 20
            return i
        }()
        
        addSubview(stackView)
    }
    
    private func configureConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        changeCamera.translatesAutoresizingMaskIntoConstraints = false
        lightMode.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            changeCamera.widthAnchor.constraint(equalToConstant: 24),
            changeCamera.heightAnchor.constraint(equalToConstant: 24),
            lightMode.widthAnchor.constraint(equalToConstant: 24),
            lightMode.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
    
}
