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

    @available(iOSApplicationExtension, unavailable)
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
        trackPushTokenRefreshedIfNecessary()
    }
    
    @objc func appWillEnterForeground() {
        Logger.verbose(message: "Application will enter foreground", category: .application)
        Ometria.sharedInstance().trackAppForegroundedEvent()
    }
    
    @objc func appWillResignActive() {
        Logger.verbose(message: "Application will resign active", category: .application)
        Ometria.sharedInstance().trackAppBackgroundedEvent()
        trackPushTokenRefreshedIfNecessary()
    }
    
    @objc func appDidBecomeActive() {
        Logger.verbose(message: "Application did become active", category: .application)
        Ometria.sharedInstance().trackAppForegroundedEvent()
    }
  
    private func trackPushTokenRefreshedIfNecessary() {
      guard let fcmToken = OmetriaDefaults.fcmToken else { return }
      let fcmTokenLastRefreshDate: Date = OmetriaDefaults.fcmTokenLastRefreshDate ?? Date()
      guard let dateOneWeekAgo: Date = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) else { return }
      if fcmTokenLastRefreshDate < dateOneWeekAgo {
        Ometria.sharedInstance().trackPushTokenRefreshedEvent(pushToken: fcmToken)
      }
    }
}
