//
//  DSSDownloadData.swift
//  DSSNetwork
//
//  Created by David on 02/04/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation

public enum DSSDownloadStatus {
    case pending, downloading, finished
}

public protocol DSSDownloadData {
//    static func done(url: URL) -> Self
    
    var status: DSSDownloadStatus { get }
    var url: URL { get }
    var progress: Float { get }
}
