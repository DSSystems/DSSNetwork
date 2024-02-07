//
//  DSSImageDownloader.swift
//  DSSNetwork
//
//  Created by David on 06/10/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import UIKit
import CoreGraphics

public typealias Map<T, U> = (T) -> U

public func identity<T>() -> Map<T, T> { { $0 } }

public typealias URLString = String

public protocol DSSImageDownloader: UIImageView {
    static var urlSession: URLSession { get }
    static var cacheManager: DSSImageCacheManager? { get set }
    
    var imageUrlString: String? { get set }
}

public extension DSSImageDownloader {
    static var urlSession: URLSession { .shared }
    
    static func set(cacheManager: DSSImageCacheManager?) {
        Self.cacheManager = cacheManager
    }
    
    func thumbnail(
        from data: Data,
        configure: @escaping Map<UIImage, UIImage?> = identity(),
        defaultImage: UIImage? = nil
    ) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        
        let frame: CGRect = UIScreen.main.bounds
        
        let size: CGSize = .init(width: frame.size.width * UIScreen.main.scale, height: frame.size.height * UIScreen.main.scale)
        
        let downsampledOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: size
        ] as [CFString : Any] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return defaultImage }
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampledOptions) else { return defaultImage }
        
        let image = configure(UIImage(cgImage: downsampledImage))
        
        return image
    }
    
    func setImage(
        from urlString: URLString,
        cacheInterval: TimeInterval,
        configure: @escaping Map<UIImage, UIImage?> = identity(),
        downsample: Bool = false,
        defaultImage: UIImage? = nil
    ) {
        guard let encUrlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),  let url = URL(string: encUrlString) /*, urlString != imageUrlString*/ else { return }
        setImage(from: url, cacheInterval: cacheInterval, configure: configure, defaultImage: defaultImage)
    }
    
    func setImage(
        from url: URL,
        cacheInterval: TimeInterval,
        configure: @escaping Map<UIImage, UIImage?> = identity(),
        downsample: Bool = false,
        defaultImage: UIImage? = nil
    ) {
        if let image = Self.cacheManager?.image(forUrl: url.absoluteString) {
            return DispatchQueue.main.async { self.image = configure(image) }
        }
        
        let handler: (Data?, URLResponse?, Error?) -> Void = { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                #if DEBUG
                print("[\(NSStringFromClass(Self.self)) \(#function)]: \(error.localizedDescription)")
                #endif
                return DispatchQueue.main.async { self.image = defaultImage == nil ? nil : configure(defaultImage!) }
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                #if DEBUG
                print("[\(NSStringFromClass(Self.self)) \(#function)]: This should never happen!")
                #endif
                return DispatchQueue.main.async { self.image = defaultImage == nil ? nil : configure(defaultImage!) }
            }
            
            guard (200...399) ~= httpResponse.statusCode else {
                #if DEBUG
                print("[\(NSStringFromClass(Self.self)) \(#function)]: [\(url.absoluteString)] The server returned an invalid status code (\(httpResponse.statusCode))")
                #endif
                return DispatchQueue.main.async { self.image = defaultImage == nil ? nil : configure(defaultImage!) }
            }
            
            guard let data = data else {
                #if DEBUG
                print("[\(NSStringFromClass(Self.self)) \(#function)]:InvalidData")
                #endif
                return DispatchQueue.main.async { self.image = defaultImage == nil ? nil : configure(defaultImage!) }
            }
            
            let image: UIImage? = {
                guard downsample else {
                    guard let image = UIImage(data: data) else { return defaultImage }
                    return configure(image)
                }
                return self.thumbnail(
                    from: data,
                    configure: configure,
                    defaultImage: defaultImage == nil ? defaultImage : configure(defaultImage!)
                )
            }()
            
            Self.cacheManager?.cache(imageData: data, forUrl: url.absoluteString, cachePeriod: cacheInterval)
            
            guard self.imageUrlString == httpResponse.url?.absoluteString else { return }
            DispatchQueue.main.async { self.image = image }
        }
        
        let dataTask = Self.urlSession.dataTask(with: url, completionHandler: handler)
        
        dataTask.resume()
        imageUrlString = url.absoluteString
    }
}
