//
//  AutomaticLifecycleTracker.swift
//  FirebaseCore
//
//  Created by Cata on 7/21/20.
//

import Foundation
import UIKit

open class AutomaticLifecycleTracker {
    
    var isRunning = false
    
    func startTracking() {
        guard !isRunning else {
            return
        }
        
        isRunning = true
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
        guard isRunning else {
            return
        }
        isRunning = false
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleDidFinishLaunch(notification: NSNotification) {
        Logger.debug(message: "Application did finish Launch")
    }
    
    @objc func appDidEnterBackground() {
        Logger.debug(message: "Application did enter background")
        Ometria.sharedInstance().trackEvent(type: .sendApplicationToBackground, value: nil)
    }
    
    @objc func appWillEnterForeground() {
        Ometria.sharedInstance().trackEvent(type: .bringApplicationToForeground, value: nil)
        Logger.debug(message: "Application will enter foreground")
    }
    
    @objc func appWillResignActive() {
        Ometria.sharedInstance().trackEvent(type: .sendApplicationToBackground, value: nil)
        Logger.debug(message: "Application will resign active")
    }
    
    @objc func appDidBecomeActive() {
        Ometria.sharedInstance().trackEvent(type: .bringApplicationToForeground, value: nil)
        Logger.debug(message: "Application did become active")
    }
}
