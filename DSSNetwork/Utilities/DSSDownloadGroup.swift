//
//  DSSDownloadGroup.swift
//  DSSNetwork
//
//  Created by David on 01/04/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation
import UIKit

public class DSSDownloadGroupProgress {
    public var status: DSSDownloadStatus = .pending
        
    public var numberOfDownloads: Int
    
    private var individualPregress: [String: Float] = [:]
    
    public var progress: Float {
        let unnormalisedProgress: Float = individualPregress.reduce(0) { (result, item) -> Float in
            return result + item.value
        }
        return unnormalisedProgress / Float(numberOfDownloads)
    }
        
    init(numberOfDownloads: Int) {
        self.numberOfDownloads = numberOfDownloads
    }
    
    public func update(progress: DSSDownloadProgress) {
        individualPregress[progress.url.absoluteString] = {
            switch progress.status {
            case .pending, .downloading: return progress.progress
            case .finished: return 1
            }
        }()
    }
}

@objc public protocol DSSDownloadGroupDelegate: AnyObject {
    @objc optional func downloadGroup(_ downloadGroup: DSSDownloadGroup, didUpdateProgress progress: Float)
    @objc optional func downloadGroup(_ downloadGroup: DSSDownloadGroup, didFinishSaveMediaToGallery mediaPath: String)
    @objc optional func downloadGroupDidFinishDownloads(_ downloadGroup: DSSDownloadGroup)
    @objc optional func downloadGroup(_ downloadGroup: DSSDownloadGroup, didFailDownloadWith error: Error?)
    @objc optional func downloadGroup(_ downloadGroup: DSSDownloadGroup, didFailSaveToGalleryWith error: Error?)
}

open class DSSDownloadGroup: NSObject {
    private var downloadInfoStack: NWStack<DSSDownloadInfo> = .init()
    private var downloadProgress: DSSDownloadGroupProgress?
        
    public weak var delegate: DSSDownloadGroupDelegate?
    
    public var numberOfDownloads: Int { return downloadInfoStack.numberOfNodes }
    
    private let fileManager: NWFileManager = .standard
    private let photoAlbumManager: DSSPhotoAlbumManager = .shared
    
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    
    private lazy var session: URLSession = {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.dssystems."
        let configuration: URLSessionConfiguration = .background(withIdentifier: "\(bundleIdentifier).background.sessions.downloadGroup")
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        return urlSession
    }()
    
    public func add(downloadUrl: URL, destinationUrl: URL, fileType: DSSDownloadInfo.FileType, photoAlbumName: String?) {
        let info: DSSDownloadInfo = .init(session: session,
                                          downloadUrl: downloadUrl,
                                          destinationUrl: destinationUrl,
                                          fileType: fileType,
                                          photoAlbumName: photoAlbumName)
        downloadInfoStack.push(info)
    }
    
    public func start() {
        downloadProgress = .init(numberOfDownloads: downloadInfoStack.numberOfNodes)
        next()
    }
    
    private func next() {
        guard let info = downloadInfoStack.peek() else {
            finish()
            delegate?.downloadGroupDidFinishDownloads?(self)
            return
        }
        
        info.task.resume()
    }
    
    private func handle(progress: DSSDownloadProgress) {
        downloadProgress?.update(progress: progress)
        guard let progressValue = downloadProgress?.progress else { return }
        delegate?.downloadGroup?(self, didUpdateProgress: progressValue)
    }
    
    open func didFinishDownload(from url: URL) {
    }
    
    public func cancel() {
        while let info = downloadInfoStack.pop() { info.task.cancel() }
        finish()
    }
    
    public func finish() {
        session.finishTasksAndInvalidate()
    }
}

extension DSSDownloadGroup: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        
        guard let info = downloadInfoStack.peek() else { return }
        guard let originalUrl = downloadTask.originalRequest?.url, info.originUrl == originalUrl else { return }
        
        let progress = DSSDownloadProgress(status: .downloading,
                                           url: originalUrl,
                                           bytesWritten: totalBytesWritten,
                                           totalBytes: totalBytesExpectedToWrite)
        handle(progress: progress)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let info = downloadInfoStack.pop() else { return }
        
        guard let originalUrl = downloadTask.originalRequest?.url, info.originUrl == originalUrl else { return }
        
        let progress = DSSDownloadProgress.done(url: originalUrl)
        handle(progress: progress)
        
        do {
            try fileManager.mv(from: location.path, to: info.destinationUrl.path)
            
            if let photoAlbumName = info.photoAlbumName {
                switch info.fileType {
                case .image:
                    guard let data = try? Data(contentsOf: info.destinationUrl), let image = UIImage(data: data) else { return }
                    photoAlbumManager.save(asset: .image(image), toAlbun: photoAlbumName) { [weak self] error in
                        if let error = error {
                            #if DEBUG
                            print("\(NSStringFromClass(Self.self)): \(error.localizedDescription)")
                            #endif
                            return
                        }
                        try? self?.fileManager.rm(url: info.destinationUrl)
                    }
                case .video:
                    photoAlbumManager.save(asset: .video(url: info.destinationUrl), toAlbun: photoAlbumName) { [weak self] error in
                        if let error = error {
                            #if DEBUG
                            print("\(NSStringFromClass(Self.self)): \(error.localizedDescription)")
                            #endif
                            return
                        }
                        try? self?.fileManager.rm(url: info.destinationUrl)
                    }
                case .none: break
                }
            }
            
            didFinishDownload(from: info.originUrl)
        } catch {
            delegate?.downloadGroup?(self, didFailSaveToGalleryWith: error)
        }
        next()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        delegate?.downloadGroup?(self, didFailDownloadWith: error)
    }
}
