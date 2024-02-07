//
//  NWImageView.swift
//  DSSNetwork
//
//  Created by David on 12/01/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import UIKit

open class NWImageView: UIImageView, DSSImageDownloader {
    public static var cacheManager: DSSImageCacheManager?
    
    public var imageUrlString: String?
}

open class NWCircularImageView: UIImageView, DSSImageDownloader {
    public static var cacheManager: DSSImageCacheManager?
    
    public var imageUrlString: String?
    
    // MARK: - Init
    
    public init(imageName name: String) {
        guard let image = UIImage(named: name) else {
            print("DSSCircularImageView: Image with name '\(name)' not found.")
            super.init(image: nil)
            return
        }
        super.init(image: image)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
    
    public init(image: UIImage) {
        super.init(image: image)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
    
    public init() {
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
    
    // MARK: - Handlers
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = min(bounds.size.width, bounds.size.height) / 2
    }
}

//open class NWImageView: UIImageView {
//    public static var defaultImage: UIImage? = nil
//
//    internal var urlString: String?
//
//    open var isLoading: Bool = false {
//        didSet {
//            image = nil
//            if #available(iOS 13.0, *) {
//                let color = UIColor(dynamicProvider: { (trait) -> UIColor in
//                    guard trait.userInterfaceStyle == .dark else { return UIColor(white: 0.95, alpha: 1) }
//                    return UIColor(white: 0.05, alpha: 1)
//                })
//                backgroundColor = isLoading ? color : .clear
//            } else {
//                backgroundColor = isLoading ? UIColor(white: 0.95, alpha: 1) : .clear
//            }
//        }
//    }
//
//    public func setImage(from url: URL, cacheManager: DSSImageCacheManager? = nil, cachePeriod: TimeInterval = 60) {
//        let urlString = url.absoluteString
//        if let image = cacheManager?.image(forUrl: urlString) {
//            self.image = image
//            return
//        }
//
//        guard let url = URL(string: urlString) else {
//            print("\(description): String provided does not correspond to an URL address.")
//            return
//        }
//
//        self.urlString = urlString
//
//        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
//            guard let self = self else { return }
//            DispatchQueue.main.async { self.isLoading = false }
//
//            if let error = error {
//                print("\(NSStringFromClass(Self.self)): \(error.localizedDescription)")
//                return
//            }
//
//            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
//                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
//                print("\(NSStringFromClass(Self.self)): Bad response (code: \(status))")
//                return
//            }
//
//            guard let data = data else {
//                print("\(NSStringFromClass(Self.self)): Bad data responce.")
//                return
//            }
//
//            guard let image = UIImage(data: data) else {
//                print("\(NSStringFromClass(Self.self)): Failed to create image from data.")
//                return
//            }
//
//            cacheManager?.cache(imageData: data, forUrl: urlString, cachePeriod: cachePeriod)
//
//            DispatchQueue.main.async {
//                guard let urlStr = self.urlString, urlStr == urlString else {
//                    self.image = Self.defaultImage
//                    return
//                }
//                self.image = image
//            }
//        }
//
//        DispatchQueue.main.async { self.isLoading = true }
//        task.resume()
//    }
//}
