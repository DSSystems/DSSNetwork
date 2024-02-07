//
//  URLResponseExtension.swift
//  DSSNetwork
//
//  Created by David on 10/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

extension URLResponse {
    var http: HTTPURLResponse? { return self as? HTTPURLResponse }
}
