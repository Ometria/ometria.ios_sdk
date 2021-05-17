//
//  AutomaticScreenViewsTracker.swift
//  Ometria
//
//  Created by Cata on 7/30/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UIKit

class AutomaticScreenViewsTracker {
    
    var isRunning = false
    
    func startTracking() {
        guard !isRunning else {
            return
        }
        
        isRunning = true
        swizzleViewDidAppear()
    }
    
    func stopTracking() {
        guard isRunning else {
            return
        }
        
        isRunning = false
        unswizzleViewDidAppear()
    }
    
    func swizzleViewDidAppear() {
        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        let swizzledSelector = #selector(UIViewController.om_viewDidAppear(_:))
       
        Swizzler.swizzleSelector(originalSelector, withSelector: swizzledSelector, for: UIViewController.self, name: "OmetriaViewDidAppear") { (_, _, _, _) in
        }
    }
    
    func unswizzleViewDidAppear() {
        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        Swizzler.unswizzleSelector(originalSelector, aClass: UIViewController.self)
    }
}

extension UIViewController {
    @objc func om_viewDidAppear(_ animated: Bool) {
        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        
        if let swizzle = Swizzler.getSwizzle(for: originalSelector, in: type(of: self)) {
            typealias MyCFunction = @convention(c) (AnyObject, Selector, Bool) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: MyCFunction.self)
            curriedImplementation(self, originalSelector, animated)
        }
        
        let screenClassName = String(describing:type(of:self))
        Logger.verbose(message: "Custom view did appear: \(screenClassName)")
        Ometria.sharedInstance().trackScreenViewedAutomaticEvent(screenName: screenClassName)
    }
}
