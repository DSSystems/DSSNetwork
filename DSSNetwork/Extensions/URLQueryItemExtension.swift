//
//  URLQueryItemExtension.swift
//  DSSNetwork
//
//  Created by David on 30/11/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

public extension URLQueryItem {
    init(name: String, value: Float) {
        self.init(name: name, value: "\(value)")
    }
    
    init?(name: String, value: Float?) {
        guard let value = value else { return nil }
        self.init(name: name, value: "\(value)")
    }
    
    init(name: String, value: Double) {
        self.init(name: name, value: "\(value)")
    }
    
    init(name: String, value: Int) {
        self.init(name: name, value: "\(value)")
    }
    
    init?(name: String, value: Int?) {
        guard let value = value else { return nil }
        self.init(name: name, value: "\(value)")
    }
    
    init(name: String, value: Int64) {
        self.init(name: name, value: "\(value)")
    }
    
    init?(name: String, value: Int64?) {
        guard let value = value else { return nil }
        self.init(name: name, value: "\(value)")
    }
    
    init<T: RawRepresentable>(name: String, value: T) {
        self.init(name: name, value: "\(value.rawValue)")
    }
}
