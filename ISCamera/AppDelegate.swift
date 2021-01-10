//
//  AppDelegate.swift
//  ISCamera
//
//  Created by Igor Sorokin on 19.12.2020.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = CameraController()
        window?.makeKeyAndVisible()
        
        return true
    }
    
}

