//
//  DataExtension.swift
//  DSSNetwork
//
//  Created by David on 13/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

extension Data {
    static func fileDataForRequestBody(_ file: DSSFile, boundary: Data) -> Data? {
        guard let keyData = "Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.filename)\"\r\n".toData,
            let contentTypeData = "Content-Type: \(file.mimetype)\r\n\r\n".toData,
            let footerData = "\r\n".toData else {
            return nil
        }
        var data = Data()
        data.append(boundary)
        data.append(keyData)
        data.append(contentTypeData)
        data.append(file.data)
        data.append(footerData)
        return data
    }
    
    static func valueDataForRequestBody(_ item: URLQueryItem, boundary: Data) -> Data? {
        guard let keyData = "Content-Disposition: form-data; name=\"\(item.name)\"\r\n\r\n".toData,
              let valueData = "\(item.value ?? "")\r\n".toData else {
            return nil
        }
        var data = Data()
        data.append(boundary)
        data.append(keyData)
        data.append(valueData)
        return data
    }
}
