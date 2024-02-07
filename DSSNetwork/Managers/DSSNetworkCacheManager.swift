//
//  DSSNetworkCacheManager.swift
//  DSSNetwork
//
//  Created by David on 10/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

public protocol DSSNetworkCacheManager {
    func networkObject<T: Codable>(for request: URLRequest) -> T?
    func cache<T: Codable>(networkObject: T, for request: URLRequest, timeInterval: TimeInterval)
}
