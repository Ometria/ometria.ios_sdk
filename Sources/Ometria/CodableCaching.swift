//
//  CodableCaching.swift
//  Ometria
//
//  Created by Cata on 8/17/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation

struct CodableCaching<T> {
    static var rootDirectory: String {
        return "OmetriaCache"
    }
    
    static var relativePath: NSString {
        let dirPath = NSSearchPathForDirectoriesInDomains( .documentDirectory, .userDomainMask, true)[0] as NSString
        return dirPath.appendingPathComponent(CodableCaching.rootDirectory) as NSString
    }
    
    init(resourceID: String, uniquePathComponent: String?) {
        let relativePath = CodableCaching.relativePath
        var uniquePath: NSString = relativePath
        if let uniquePathComponent {
            uniquePath = relativePath.appendingPathComponent(uniquePathComponent) as NSString
        }
        self.filePath = uniquePath.appendingPathComponent(resourceID).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    }
    
    var filePath: String!
    var fileName: String {
        return (filePath as NSString).lastPathComponent
    }
    
    
    static func deleteCachingDirectory() {
        let path = CodableCaching.relativePath
        
        do {
            try FileManager.default.removeItem(atPath: path as String)
        } catch let error as NSError {
            Logger.error(message: "CodableCaching: Failed to delete file \(path)\n\(error)", category: .cache)
        }
    }
}

extension CodableCaching where T: Codable {
    /// load json file from disk and tranlate into an mappable object
    func loadFromFile() -> T? {
        let path = filePath as String
        Logger.verbose(message: "CodableCaching: \(String(describing: T.self)) - Loading \(fileName) from file.", category: .cache)
        
        do {
            guard let jsonData = try loadContentFromFile() else {
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(T.self, from: jsonData)
        } catch let error as NSError {
            Logger.error(message: "CodableCaching: Failed to load JSON \(path)\n\(error)", category: .cache)
        }
        
        return nil
    }
    
    
    /// will save object as json file on disk
    /// - on nil --> file is deleted
    func saveToFile(_ object: T?, async: Bool = true){
        guard let object = object else {
            removeFile(path: filePath)
            return
        }
        
        let save = {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let jsonData = try encoder.encode(object)
                try self.saveToFile(data: jsonData)
            } catch let error as NSError {
                Logger.error(message: "CodableCaching: ERROR saving: \(error)", category: .cache)
            }
        }
        
        Logger.verbose(message: "CodableCaching: \(String(describing: T.self)) - Saving \'\(fileName)\' to file.", category: .cache)
        if async {
            DispatchQueue.global(qos: .background).async {
                save()
            }
        } else {
            save()
        }
    }
}

extension CodableCaching {
    fileprivate func loadContentFromFile() throws -> Data? {
        if FileManager.default.fileExists(atPath: filePath) == false {
            return nil
        }
        
        return try Data(contentsOf: URL(fileURLWithPath: filePath), options: [])
    }
    
    fileprivate func saveToFile(data: Data) throws {
        // Create directory if necessary
        let fileManager = FileManager.default
        let filePath = self.filePath as NSString
        
        if !fileManager.fileExists(atPath: filePath.deletingLastPathComponent) {
            try fileManager.createDirectory(atPath: filePath.deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
        }
        
        // write data
        try data.write(to: URL(fileURLWithPath: self.filePath))
    }
    
    fileprivate func removeFile(path: String) {
        do {
            try FileManager.default.removeItem(atPath: path as String)
        } catch let error as NSError {
            Logger.error(message: "CodableCaching: Failed to delete file \(path)\n\(error)", category: .cache)
        }
    }
}

