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
        
        notificationCenter.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    deinit {
        stopTracking()
    }
    
    func stopTracking() {
        guard isRunning else {
            return
        }
        isRunning = false
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleDidFinishLaunch(notification: NSNotification) {
        Logger.verbose(message: "Application did finish Launch", category: .application)
    }
    
    @objc func appWillTerminate() {
        Logger.verbose(message: "Application will terminate", category: .application)
    }
    
    @objc func appDidEnterBackground() {
        Logger.verbose(message: "Application did enter background", category: .application)
        Ometria.sharedInstance().trackAppBackgroundedEvent()
    }
    
    @objc func appWillEnterForeground() {
        Ometria.sharedInstance().trackAppForegroundedEvent()
        Logger.verbose(message: "Application will enter foreground", category: .application)
    }
    
    @objc func appWillResignActive() {
        Ometria.sharedInstance().trackAppBackgroundedEvent()
        Logger.verbose(message: "Application will resign active", category: .application)
    }
    
    @objc func appDidBecomeActive() {
        Ometria.sharedInstance().trackAppForegroundedEvent()
        Logger.verbose(message: "Application did become active", category: .application)
    }
}
