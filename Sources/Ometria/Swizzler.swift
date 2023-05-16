//
//  Swizzler.swift
//  Ometria
//
//  Created by Cata on 7/17/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

extension DispatchQueue {
    private static var _onceTracker = [String]()
    
    class func once(token: String, block: () -> Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        if _onceTracker.contains(token) {
            return
        }
        _onceTracker.append(token)
        block()
    }
}

class Swizzler {
    static var swizzles = [String: Swizzle]()
    
    class func getSwizzleKey(for selector: Selector, in aClass: AnyClass) -> String {
        return "\(selector)-\(aClass)"
    }
    
    class func getSwizzle(for selector: Selector, in aClass: AnyClass) -> Swizzle? {
        let key = getSwizzleKey(for: selector, in: aClass)
        return swizzles[key]
    }
    
    class func removeSwizzle(for selector: Selector, in aClass: AnyClass) {
        let key = getSwizzleKey(for: selector, in: aClass)
        swizzles.removeValue(forKey: key)
    }
    
    class func setSwizzle(_ swizzle: Swizzle, for selector: Selector, in aClass: AnyClass) {
        let key = getSwizzleKey(for: selector, in: aClass)
        swizzles[key] = swizzle
    }
    
    class func swizzleSelector(
        _ originalSelector: Selector,
        withSelector newSelector: Selector,
        for aClass: AnyClass,
        name: String,
        block: @escaping ((
            _ view: AnyObject?,
            _ command: Selector,
            _ param1: AnyObject?,
            _ param2: AnyObject?
        ) -> Void)) {
            if let swizzledMethod = class_getInstanceMethod(aClass, newSelector) {
                
                let swizzledMethodImplementation = method_getImplementation(swizzledMethod)
                
                if let originalMethod = class_getInstanceMethod(aClass, originalSelector) {
                    let originalMethodImplementation = method_getImplementation(originalMethod)
                    
                    var swizzle = getSwizzle(for: originalSelector, in: aClass)
                    if swizzle == nil {
                        swizzle = Swizzle(block: block,
                                          name: name,
                                          aClass: aClass,
                                          selector: originalSelector,
                                          originalMethod: originalMethodImplementation)
                        setSwizzle(swizzle!, for: originalSelector, in: aClass)
                    } else {
                        swizzle?.blocks[name] = block
                    }
                    
                    let didAddMethod = class_addMethod(aClass,
                                                       originalSelector,
                                                       swizzledMethodImplementation,
                                                       method_getTypeEncoding(swizzledMethod))
                    if didAddMethod {
                        setSwizzle(swizzle!, for: originalSelector, in: aClass)
                    } else {
                        method_setImplementation(originalMethod, swizzledMethodImplementation)
                    }
                } else {
                    let didAddMethod = class_addMethod(aClass,
                                                       originalSelector,
                                                       swizzledMethodImplementation,
                                                       method_getTypeEncoding(swizzledMethod))
                    if !didAddMethod {
                        Logger.verbose(message: "Swizzling error: Could not implement method "
                                       + "\(NSStringFromSelector(originalSelector)) on \(NSStringFromClass(aClass))")
                    }
                }
            } else {
                Logger.verbose(message: "Swizzling error: Cannot find method for "
                               + "\(NSStringFromSelector(newSelector)) on \(NSStringFromClass(aClass))")
            }
        }
    
    class func unswizzleSelector(_ selector: Selector, aClass: AnyClass, name: String? = nil) {
        if let method = class_getInstanceMethod(aClass, selector),
           let swizzle = getSwizzle(for: selector, in: aClass) {
            if let name = name {
                swizzle.blocks.removeValue(forKey: name)
            }
            
            if name == nil || swizzle.blocks.count < 1 {
                method_setImplementation(method, swizzle.originalMethod)
                removeSwizzle(for: selector, in: aClass)
            }
        }
    }
}

class Swizzle: CustomStringConvertible {
    let aClass: AnyClass
    let selector: Selector
    let originalMethod: IMP
    var blocks = [String: ((view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) -> Void)]()
    
    init(block: @escaping ((_ view: AnyObject?, _ command: Selector, _ param1: AnyObject?, _ param2: AnyObject?) -> Void),
         name: String,
         aClass: AnyClass,
         selector: Selector,
         originalMethod: IMP) {
        self.aClass = aClass
        self.selector = selector
        self.originalMethod = originalMethod
        self.blocks[name] = block
    }
    
    var description: String {
        var retValue = "Swizzle on \(NSStringFromClass(type(of: self)))::\(NSStringFromSelector(selector)) ["
        for (key, value) in blocks {
            retValue += "\t\(key) : \(String(describing: value))\n"
        }
        return retValue + "]"
    }
    
    
}
