//
//  DSSNError.swift
//  DSSNetwork
//
//  Created by David on 13/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

protocol DSSNError: Error {
    var code: Int { get }
    var nsError: NSError { get }
}

public protocol DSSServerErrorModel {
    var didFindError: Bool { get }
}
