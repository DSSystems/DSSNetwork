//
//  UIImageViewExtension.swift
//  DSSNetwork
//
//  Created by David on 22/12/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import UIKit

public protocol DSSImageCacheManager {
    func image(forUrl urlString: String) -> UIImage?
    func cache(imageData data: Data, forUrl urlString: String, cachePeriod: TimeInterval)
}
