//
//  DSSPhotoAlbumManager.swift
//  DSSCukara
//
//  Created by David on 11/04/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Photos
import UIKit.UIImage

open class DSSPhotoAlbumManager {
    enum Asset {
        case image(UIImage), video(url: URL)
    }
    
    public static let shared = DSSPhotoAlbumManager()
    public var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    private init() { }
    
    public func checkPhotoAlbumPermisions(_ completion: ((PHAuthorizationStatus) -> Void)?) {
        guard PHPhotoLibrary.authorizationStatus() != .authorized else {
            completion?(.authorized)
            return
        }
        
        let handler: (PHAuthorizationStatus) -> Void = { [weak self] status in
            self?.authorizationStatus = status
            completion?(status)
        }
        
        PHPhotoLibrary.requestAuthorization(handler)
    }
    
    func album(name: String, _ completion: @escaping (Result<PHAssetCollection, Error>) -> Void) {
        if let asset = asset(name: name) {
            completion(.success(asset))
            return
        }
        
        let chageBlock: () -> Void = {
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        }
        
        let handler: (Bool, Error?) -> Void = { [weak self] (success, error) in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard success else { fatalError("\(NSStringFromClass(Self.self)): This should never happen?") }
            completion(.success(self.asset(name: name)!))
        }
        
        PHPhotoLibrary.shared().performChanges(chageBlock, completionHandler: handler)
    }
    
    func asset(name: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        guard let asset = collection.firstObject else { return nil }
        return asset
    }
    
    func save(asset: Asset, toAlbun name: String, _ completion: @escaping (Error?) -> Void) {
        let changeBlock: (PHAssetCollection) -> Void = { assetCollection in
            let assetChangeRequest: PHAssetChangeRequest = {
                switch asset {
                case .image(let image): return PHAssetChangeRequest.creationRequestForAsset(from: image)
                case .video(let url):
                    guard let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) else {
                        fatalError("\(NSStringFromClass(Self.self)): This should never happen?")
                    }
                    return request
                }
            }()
            guard let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset,
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection) else {
                fatalError("\(NSStringFromClass(Self.self)): This should never happen?")
            }
            
            let fastEnumeration = NSArray(array: [assetPlaceholder] as [PHObjectPlaceholder])
            albumChangeRequest.addAssets(fastEnumeration)
        }
        
        let handler: (Result<PHAssetCollection, Error>) -> Void = { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let assetCollection):
                PHPhotoLibrary.shared().performChanges({
                    changeBlock(assetCollection)
                }) { (success, error) in
                    if let error = error { completion(error) }
                    completion(nil)
                }
            }
        }
        
        album(name: name, handler)
    }
}
