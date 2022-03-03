//
//  Logger.swift
//  Ometria
//
//  Created by Cata on 7/22/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let cache = OSLog(subsystem: subsystem, category: "Cache")
    static let push = OSLog(subsystem: subsystem, category: "PushNotifications")
    static let application = OSLog(subsystem: subsystem, category: "Application")
    static let events = OSLog(subsystem: subsystem, category: "Events")
    static let general = OSLog(subsystem: subsystem, category: "General")
}

enum LogCategory: String {
    case ui, network, cache, push, application, events, general
    
    func log() -> OSLog {
        switch self {
        case .ui:
            return OSLog.ui
        case .network:
            return OSLog.network
        case .cache:
            return OSLog.cache
        case .push:
            return OSLog.push
        case .application:
            return OSLog.application
        case .events:
            return OSLog.events
        case .general:
            return OSLog.general
        }
    }
}

open enum LogLevel: String {
    case verbose
    case debug
    case info
    case warning
    case error
    
    func OSLogType() -> OSLogType {
        switch self {
        case .verbose:
            return .default
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .fault
        case .error:
            return .error
        }
    }
}

class Logger {
    private static var enabledLevels = Set<LogLevel>()
    private static let concurrencyLock: ReadWriteLock = ReadWriteLock(label: "com.ometria.Logger")
    
    open class func enableLevel(_ level: LogLevel) {
        concurrencyLock.write {
            enabledLevels.insert(level)
        }
        
    }
    
    open class func disableLevel(_ level: LogLevel) {
        concurrencyLock.write {
            enabledLevels.remove(level)
        }
    }
    
    open class func verbose(message: @autoclosure() -> Any,
                            _ path: String = #file,
                            _ function: String = #function,
                            category: LogCategory = .general)
    {
        var enabledLevels = Set<LogLevel>()
        concurrencyLock.read {
            enabledLevels = self.enabledLevels
        }
        
        guard enabledLevels.contains(.verbose) else { return }
        
        showMessageInConsole(message: "\(message())", file: path, function: function, category: category, level: .verbose)
    }
    
    open class func debug(message: @autoclosure() -> Any,
                          _ path: String = #file,
                          _ function: String = #function,
                          category: LogCategory = .general)
    {
        var enabledLevels = Set<LogLevel>()
        concurrencyLock.read {
            enabledLevels = self.enabledLevels
        }
        
        guard enabledLevels.intersection([.debug, .verbose]).count > 0 else { return }
        
        showMessageInConsole(message: "\(message())", category: category, level: .debug)
    }
    
    open class func info(message: @autoclosure() -> Any,
                         _ path: String = #file,
                         _ function: String = #function,
                         category: LogCategory = .general)
    {
        var enabledLevels = Set<LogLevel>()
        concurrencyLock.read {
            enabledLevels = self.enabledLevels
        }
        
        guard enabledLevels.intersection([.debug, .verbose, .info]).count > 0 else { return }
        
        showMessageInConsole(message: "\(message())", category: category, level: .info)
    }
    
    open class func warning(message: @autoclosure() -> Any,
                            _ path: String = #file,
                            _ function: String = #function,
                            category: LogCategory = .general)
    {
        var enabledLevels = Set<LogLevel>()
        concurrencyLock.read {
            enabledLevels = self.enabledLevels
        }
        
        guard enabledLevels.intersection([.debug, .verbose, .info, .warning]).count > 0 else { return }
        
        showMessageInConsole(message: "\(message())", category: category, level: .warning)
    }
    
    open class func error(message: @autoclosure() -> Any,
                          _ path: String = #file,
                          _ function: String = #function,
                          category: LogCategory = .general)
    {
        var enabledLevels = Set<LogLevel>()
        concurrencyLock.read {
            enabledLevels = self.enabledLevels
        }
        
        guard enabledLevels.intersection([.debug, .verbose, .info, .warning, .error]).count > 0 else { return }
        
        showMessageInConsole(message: "\(message())", category: category, level: .error)
    }
    
    private class func systemLog(message: String, level: LogLevel, category: LogCategory) {
        if #available(iOS 12, *) {
            os_log(level.OSLogType(), log: category.log(), "%@", message)
        }
    }
    
    private class func showMessageInConsole(message: String, file: String? = nil, function: String? = nil, category: LogCategory, level: LogLevel) {
        var additionalInfo = ""
        
        if file != nil || function != nil {
            let elements = [file, function].compactMap({$0})
            additionalInfo = " " + elements.joined(separator: ", ") + ":"
        }
        
        let finalMessage = "OmetriaSDK -\(additionalInfo) \(message)"
        
        if #available(iOS 12, *) {
            systemLog(message: finalMessage, level: level, category: category)
        } else {
            print("[\(category)] " + finalMessage)
        }
    }
}
