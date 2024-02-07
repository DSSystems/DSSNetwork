//
//  DSSImageSource.swift
//  DSSNetwork
//
//  Created by David on 09/02/21.
//  Copyright © 2021 DS_Systems. All rights reserved.
//

import Foundation

public enum DSSImageSource: Equatable {
    case network(url: String), bundle(name: String)
    
    public init?(url: URLString?) {
        guard let url = url else { return nil }
        self = .network(url: url)
    }
    
    public init?(imageName: String?) {
        guard let name = imageName else { return nil }
        self = .bundle(name: name)
    }
}
