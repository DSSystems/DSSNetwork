//
//  DSSDownloadInfo.swift
//  DSSNetwork
//
//  Created by David on 01/04/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation
import UIKit.UIImage

open class DSSDownloadInfo: NSObject {
    public enum FileType {
        case image
        case video
        case none
    }
    
    let task: URLSessionDownloadTask
    let destinationUrl: URL
    let fileType: FileType
    let photoAlbumName: String?
    
    var originUrl: URL {
        guard let url = task.currentRequest?.url else { fatalError("This should never happen!") }
        return url
    }
    
    init(task: URLSessionDownloadTask, destinationUrl url: URL, fileType: FileType, photoAlbumName: String?) {
        self.task = task
        self.destinationUrl = url
        self.fileType = fileType
        self.photoAlbumName = photoAlbumName
    }
    
    init(session: URLSession, downloadUrl: URL, destinationUrl: URL, fileType: FileType, photoAlbumName: String?) {
        task = session.downloadTask(with: downloadUrl)
        self.destinationUrl = destinationUrl
        self.fileType = fileType
        self.photoAlbumName = photoAlbumName
    }
}
