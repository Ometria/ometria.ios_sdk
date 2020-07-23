//
//  AutomaticLifecycleTracker.swift
//  FirebaseCore
//
//  Created by Cata on 7/21/20.
//

import Foundation
import UIKit

open class AutomaticLifecycleTracker {
    
    func startTracking() {
        let notificationCenter = NotificationCenter.default
        
        if #available(iOS 13.0, *), Ometria.doesAppUseScenes() {
            notificationCenter.removeObserver(self, name: UIScene.didEnterBackgroundNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(appDidEnterBackground), name: UIScene.didEnterBackgroundNotification, object: nil)
            
            notificationCenter.removeObserver(self, name: UIScene.willEnterForegroundNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(appWillEnterForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            notificationCenter.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
            
            notificationCenter.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }
    
    func stopTracking() {
        
    }
    
    @objc func handleDidFinishLaunch(notification: NSNotification) {
        
    }
    
    @objc func appDidEnterBackground() {
        
    }
    
    @objc func appWillEnterForeground() {
        
    }
    
    @objc func appWillResignActive() {
        
    }
    
    @objc func appDidBecomeActive() {
        
    }
}
