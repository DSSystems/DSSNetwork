//
//  NWFileManager.swift
//  DSSNetwork
//
//  Created by David on 02/04/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation
import UIKit

enum NWFileError: DSSNError {
    case notFound(path: String)
    case unwrap(varName: String)
    
    var code: Int {
        switch self {
        case .notFound: return 0
        case .unwrap: return 1
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .notFound(let key):
            let description = "LOCAL:File not found".localized
            return "\(description): key = \(key)."
        case .unwrap(let varName):
            let description = "LOCAL:Failed to unwrap variable".localized
            return "\(description): \(varName)"
        }
    }
    
    var nsError: NSError {
        let domain = String(describing: type(of: self))
        let error = NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        return error
    }
}

class NWFileManager {
    typealias DirectoryPath = String
    
    struct Item {
        enum ElementType { case directory, file }
        let type: ElementType
        let name: String
    }
    
    static let standard = NWFileManager()
    let manager = FileManager.default
    let documentDirectory: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch { fatalError("This should not happen: \(error.localizedDescription)") }
    }()
    
    private var currentUrlDirectory: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch { fatalError("This should not happen: \(error.localizedDescription)") }
    }()
    
    var currentDirectory: String {
        return currentUrlDirectory.path
    }
    
    private init() { }
    
    func mv(from currentPath: DirectoryPath, to newPath: DirectoryPath) throws {
        let currentUrl = URL(fileURLWithPath: currentPath)
        let newUrl = URL(fileURLWithPath: newPath)
        
        try manager.moveItem(at: currentUrl, to: newUrl)
    }
    
    func moveToDocumentDirectory(from currentPath: String, name: String) throws {
        let documentDirectory = try manager.url(for: .documentDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil, create: false)
        
        try mv(from: currentPath, to: documentDirectory.appendingPathComponent(name).path)
    }
    
    func ls(at url: URL) -> [Item] {
        do {
            let items = try manager.contentsOfDirectory(at: url,
                                                        includingPropertiesForKeys: [URLResourceKey.isDirectoryKey],
                                                        options: .skipsHiddenFiles)
            return items.map({
                return Item(type: $0.hasDirectoryPath ? .directory : .file, name: $0.lastPathComponent)
            })
        } catch {
            print("Failed to list contents of '\(url.path)'. \(error.localizedDescription)")
            return []
        }
    }
    
    func ls(at path: DirectoryPath = "./") -> [Item] {
        let url: URL = fullUrlPath(for: path)
        return ls(at: url)
    }
    
    func cd(at path: String = "./") {
        currentUrlDirectory = fullUrlPath(for: path)
    }
    
    func rename(path: DirectoryPath? = nil, currectName: String, newName: String) throws {
        
        let url: URL = {
            if let path = path {
                return URL(fileURLWithPath: path)
            } else {
                return documentDirectory
            }
        }()
        
        try mv(from: url.appendingPathComponent(currectName).path, to: url.appendingPathComponent(newName).path)
    }
        
    func write(data: Data?, at url: URL, name: String) throws {
        guard let data = data else { return }
        try data.write(to: url.appendingPathComponent(name), options: .atomic)
    }
    
    func write(data: Data?, at path: DirectoryPath = "./", name: String) throws {
        let url: URL = fullUrlPath(for: path)
        try write(data: data, at: url, name: name)
    }
    
    func readData(at url: URL, name: String) throws -> Data {
        let path = url.appendingPathComponent(name).path
        guard let fileData = manager.contents(atPath: path) else {
            throw NWFileError.notFound(path: url.path)
        }
        return fileData
    }
    
    func readData(at path: DirectoryPath = "./", name: String) throws -> Data {
        let url: URL = fullUrlPath(for: path)
        return try readData(at: url, name: name)
    }
    
    func mkdir(at path: DirectoryPath? = nil, name: String) throws {
        let url: URL = {
            if let path = path {
                return URL(fileURLWithPath: path)
            } else {
                return documentDirectory
            }
        }()
        
        guard !manager.directoryExists(at: url.appendingPathComponent(name).path) else { return }
        
        try manager.createDirectory(at: url.appendingPathComponent(name),
                                    withIntermediateDirectories: true,
                                    attributes: nil)
    }
    
    func rm(url: URL) throws { try manager.removeItem(at: url) }
    
    func rm(at path: DirectoryPath, filename: String? = nil) throws {
        let url = fullUrlPath(for: path)
        guard let filename = filename else {
            return try rm(url: url)
        }
        return try rm(url: url.appendingPathComponent(filename))
    }
        
    private func fullUrlPath(for relativePath: DirectoryPath) -> URL {
        let components: [String] = relativePath.split(separator: "/").map({ String($0) })
        var url = currentUrlDirectory
        components.forEach {
            switch $0 {
            case ".": break
            case "..": url = url.deletingLastPathComponent()
            default: url = url.appendingPathComponent($0)
            }
        }
        return url
    }
}

fileprivate extension Array where Element == NWFileManager.Item {
    func log() {
        self.forEach {
            let typeDescription = $0.type == .directory ? "Directory" : "File"
            print("\(typeDescription): \($0.name)")
        }
    }
}

fileprivate extension FileManager {
    func directoryExists(at path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    func directoryExists(at url: URL) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
