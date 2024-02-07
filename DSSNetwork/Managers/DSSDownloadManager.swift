//
//  DSSDownloadManager.swift
//  DSSNetwork
//
//  Created by David on 27/02/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation
import UIKit

public struct DSSDownloadProgress: DSSDownloadData {
    public static func done(url: URL) -> DSSDownloadProgress {
        return .init(status: .finished, url: url, bytesWritten: 1, totalBytes: 1)
    }
    
    public var status: DSSDownloadStatus
    public var url: URL
    public let bytesWritten: Int64
    public let totalBytes: Int64
    
    public var progress: Float {
        return Float(bytesWritten) / Float(totalBytes)
    }
    
    init(status: DSSDownloadStatus, url: URL, bytesWritten: Int64, totalBytes: Int64) {
        self.status = status
        self.url = url
        self.bytesWritten = bytesWritten
        self.totalBytes = totalBytes
    }
}

public protocol DSSDownloadCacheManager {
    func downloadedObject(forKey key: String) -> Data?
    func cache(data: Data, forKey key: String, timeInterval: TimeInterval)
}

public extension Notification.Name {
    static func name(fromUrl url: String) -> Notification.Name { return .init(url) }
}

open class DSSDownloadManager: NSObject {
    // MARK: - Properties
    
    public typealias DirectoryPath = String
    
    public static let shared = DSSDownloadManager()
    
    private let fileManager: NWFileManager = .standard
    private let queue: OperationQueue = .init()
    
    public lazy var session: URLSession = .init(configuration: .default, delegate: self, delegateQueue: queue)
//    public var cacheManager: DSSDownloadCacheManager?
    private lazy var photoAlbumManager: DSSPhotoAlbumManager = .shared
    
    internal var downloadContentInfo: Set<DSSDownloadInfo> = []
    
    internal var tempDownloadInfo: DSSDownloadInfo?
    
    // MARK: - Init
    
    private override init() {
        super.init()
    }
    
    public func download(fromUrlString urlString: String, _ completion: @escaping (Result<Data, Error>) -> Void) {
        guard let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedUrlString) else { return }
        download(fromUrl: url, completion)
    }
    
    public func download(fromUrl url: URL, _ completion: @escaping (Result<Data, Error>) -> Void) {
        let session: URLSession = URLSession.shared
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...399) ~= httpResponse.statusCode else {
                let description = "\("LOCAL:ServerReturnedAnInvalidStatusCode".localized): \((response as? HTTPURLResponse)?.statusCode ?? -1)"
                let error = NSError(domain: response?.url?.absoluteString ?? "N/A",
                                    code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: description])
                completion(.failure(error as Error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: response?.url?.absoluteString ?? "N/A",
                                    code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: "LOCAL:InvalidData".localized])
                completion(.failure(error as Error))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
    
//    public func download(fromUrlString urlString: String, saveToPath outputPath: DirectoryPath) {
//        guard let url = URL(string: urlString) else { return }
//        download(from: url, saveToPath: outputPath)
//    }
    
    public func download(_ downloadInfo: DSSDownloadInfo) {
        var request = URLRequest(url: downloadInfo.originUrl)
        request.networkServiceType = .video
        let task = session.downloadTask(with: request)
                
        downloadContentInfo.insert(downloadInfo)
        
        task.resume()
    }
}

extension DSSDownloadManager: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        
        if let url = downloadTask.currentRequest?.url {
            let progress = DSSDownloadProgress(status: .downloading,
                                               url: url,
                                               bytesWritten: totalBytesWritten,
                                               totalBytes: totalBytesExpectedToWrite)
            NotificationCenter.default.post(name: .name(fromUrl: url.absoluteString), object: progress)
        }
//        print("Downloading: \(Float(totalBytesWritten)/Float(totalBytesExpectedToWrite) * 100)")
    }
    
    private func saveToLibrary(photoAlbumName: String,
                               origin url: URL,
                               fileType: DSSDownloadInfo.FileType,
                               _ completion: (() -> Void)?) {
        switch fileType {
        case .image:
            guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return }
            photoAlbumManager.save(asset: .image(image), toAlbun: photoAlbumName) { error in
                if let error = error {
                    print("\(NSStringFromClass(Self.self)): \(error.localizedDescription)")
                    return
                }
                
                completion?()
            }
        case .video:
            photoAlbumManager.save(asset: .video(url: url), toAlbun: photoAlbumName) { error in
                if let error = error {
                    print("\(NSStringFromClass(Self.self)): \(error.localizedDescription)")
                    return
                }
                completion?()
            }
        case .none: completion?()
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        for info in downloadContentInfo {
            if info.task == downloadTask {
                do {
                    try fileManager.mv(from: location.path, to: info.destinationUrl.path)
                    
                    if let photoAlbumName = info.photoAlbumName {
                        saveToLibrary(photoAlbumName: photoAlbumName, origin: info.destinationUrl, fileType: info.fileType) { [weak self] in
                            try? self?.fileManager.rm(url: info.destinationUrl)
                            if let url = downloadTask.originalRequest?.url {
                                let object = DSSDownloadProgress.done(url: url)
                                NotificationCenter.default.post(name: .name(fromUrl: url.absoluteString), object: object)
                            }
                        }
                    } else {
                        if let url = downloadTask.originalRequest?.url {
                            let object = DSSDownloadProgress.done(url: url)
                            NotificationCenter.default.post(name: .name(fromUrl: url.absoluteString), object: object)
                        }
                    }
                } catch {
                    print("\(description): Failed to save downloaded file.")
                }
                
                downloadContentInfo.remove(info)
                break
            }
        }
//        print("Download finished, url: \(location.absoluteString)")
    }
}
