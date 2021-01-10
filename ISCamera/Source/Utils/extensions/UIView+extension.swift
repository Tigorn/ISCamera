//
//  UIView+extension.swift
//  ISCamera
//
//  Created by Igor Sorokin on 06.01.2021.
//

import UIKit

extension UIView {
    
    func showBlurSnapshot() -> UIView? {
        guard let snapshot = snapshotView(afterScreenUpdates: false) else { return nil }
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        
        snapshot.alpha = 0
        
        snapshot.addSubview(blurView)
        insertSubview(snapshot, at: 0)
        
        snapshot.frame = frame
        blurView.frame = snapshot.bounds
        
        UIView.animate(withDuration: 0.2) {
            snapshot.alpha = 1
        }
        
        return snapshot
    }
    
    func removeFadeIn() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
    
}
