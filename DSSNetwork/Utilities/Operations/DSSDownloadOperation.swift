//
//  DSSDownloadOperation.swift
//  DSSNetwork
//
//  Created by David on 01/04/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation

class DSSDownloadOperation: DSSAsyncOperation {
    private var task: URLSessionDownloadTask
    
    let info: DSSDownloadInfo
    
    init(session: URLSession, info: DSSDownloadInfo) {
        task = session.downloadTask(with: info.originUrl)
        self.info = info
    }
    
    override func main() {
        task.resume()
    }
    
    override func cancel() {
        task.cancel()
        super.cancel()
    }
}
