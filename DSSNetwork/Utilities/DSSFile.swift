//
//  DSSFile.swift
//  DSSNetwork
//
//  Created by David on 07/04/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import UIKit.UIImage

public struct DSSFile {
    public enum Compression {
        case none
        case jpeg(quality: CGFloat)
    }
    
    let name: String
    let filename: String
    let data: Data
    let mimetype: String
    
    public init(name: String, filename: String, data: Data, mimetype: String) {
        self.name = name
        self.filename = filename
        self.data = data
        self.mimetype = mimetype
    }
    
    public init(name: String, filename: String, image: UIImage, compression: Compression = .none) {
        self.name = name
        self.filename = filename
        switch compression {
        case .none:
            guard let data = image.pngData() else { fatalError("DSSEndpoint: Failed to convert UIImage to Data.") }
            self.data = data
            mimetype = "image/png"
        case .jpeg(let quality):
            guard let data = image.jpegData(compressionQuality: min(1, quality)) else { fatalError("DSSEndpoint: Failed to convert UIImage to Data.") }
            self.data = data
            mimetype = "image/jpeg"
        }
    }
}
