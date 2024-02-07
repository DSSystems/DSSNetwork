//
//  DSSEndpointError.swift
//  DSSNetwork
//
//  Created by David on 10/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import UIKit

public enum DSSEndpointError: Error {
    case data(varName: String)
    
    public var localizedDescription: String {
        switch self {
        case .data(let varName):
            let description = "LOCAL:Failed to transform element into Data".localized
            return "\(description): \(varName)."
        }
    }
}

public enum DSSHTTPRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public protocol DSSXMLEncoder {
    associatedtype T
    func encode(_ object: T) throws -> Data
}

public struct DSSBodyData {
    public enum ContentType {
        case json
        case xml
        case custom(String)
        
        var description: String {
            switch self {
            case .json: return "application/json"
            case .xml: return "text/xml"
            case .custom(let value): return value
            }
        }
    }
        
    let content: Data?
    let contentType: ContentType
    
    public init<T: Encodable>(object: T, contentType: ContentType) {
        switch contentType {
        case .json: self.content = try? JSONEncoder().encode(object)
        case .xml, .custom: fatalError("For XML format use the DSSBodyData(object:xmlEncoder:) initializer.")
        }
        self.contentType = contentType
    }
    
    public init<T, Encoder: DSSXMLEncoder>(object: T, xmlEncoder: Encoder) throws where T == Encoder.T {
        self.contentType = .xml
        self.content = try xmlEncoder.encode(object)
    }
    
    public init(data: Data, contentType: ContentType) {
        self.content = data
        self.contentType = contentType
    }
    
    public static func json<T: Encodable>(from object: T) -> Self {
        self.init(object: object, contentType: .json)
    }
    
    public func printAsDictionary() {
        guard let data = content else { return }
        guard let object = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else { return }
        guard let dictionary = object as? [String: Any] else { return }
        
        #if DEBUG
        print(dictionary)
        #else
        print("[\(#function)]: Could not print Dictionary in RELEASE build.")
        #endif
    }
    
    public func printAsJSON() {
        guard let data = content else { return }
        guard let string = String(data: data, encoding: .utf8) else { return }
        
        #if DEBUG
        print("[\(#function)]:\n\(string)")
        #else
        print("[\(#function)]: Could not print JSON in RELEASE build.")
        #endif
    }
}

public protocol DSSNetworkEndpoint {
    associatedtype NetworkClient: DSSNetworkClient
    var baseUrl: String { get }
    var key: String { get }
    var path: String { get }
    var method: DSSHTTPRequestMethod { get }
    var headers: [String: String] { get }
    var parameters: [URLQueryItem] { get }
    var body: [URLQueryItem] { get }
    var bodyData: DSSBodyData? { get }
    var files: [DSSFile] { get }
    var cachePolicy: URLRequest.CachePolicy? { get }
    var cacheInterval: TimeInterval { get }
    var jsonDecoderStrategy: JSONDecoder.KeyDecodingStrategy { get }
}

public extension DSSNetworkEndpoint {
    var baseUrl: String { return NetworkClient.baseUrl }
    var key: String { return NetworkClient.key }
    var parameters: [URLQueryItem] { return [] }
    var body: [URLQueryItem] { return [] }
    var bodyData: DSSBodyData? { return nil }
    var files: [DSSFile] { return [] }
    var cachePolicy: URLRequest.CachePolicy? { return nil }
    var timeoutInterval: TimeInterval { return 60 }
    var method: DSSHTTPRequestMethod { return .get }
        
    var headers: [String: String] { return [:] }
    
    var cacheInterval: TimeInterval { return 0 }
    
    var jsonDecoderStrategy: JSONDecoder.KeyDecodingStrategy { return .useDefaultKeys }
    
    private var urlComponent: URLComponents? {
        var urlComponent = URLComponents(string: baseUrl)
        urlComponent?.path = path.first == "/" ? path : "/\(path)"
        urlComponent?.queryItems = parameters
        return urlComponent
    }
    
    var request: URLRequest {
        guard let url = urlComponent?.url else { fatalError("Failed to parse URL from URLComponents.") }
        
        let boundary = UUID().uuidString
        if let cachePolicy = cachePolicy {
            var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
            headers.forEach({ request.setValue($0.value, forHTTPHeaderField: $0.key) })
            do {
                if let bodyData = bodyData, let data = bodyData.content {
                    request.httpBody = data
                    request.setValue(bodyData.contentType.description, forHTTPHeaderField: "Content-Type")
                } else {
                    request.httpBody = try requestBody(boundary: boundary, parameters: body, files: files)
                    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                #if DEBUG
                print("DSSNetworkEndpoint: ", (error as NSError).debugDescription)
                #endif
            }
            request.httpMethod = method.rawValue
            return request
        }
        
        var request = URLRequest(url: url)
        headers.forEach({ request.setValue($0.value, forHTTPHeaderField: $0.key) })
        do {
            if let bodyData = bodyData, let data = bodyData.content {
                request.httpBody = data
                request.setValue(bodyData.contentType.description, forHTTPHeaderField: "Content-Type")
            } else {
                request.httpBody = try requestBody(boundary: boundary, parameters: body, files: files)
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            }
        } catch {
            #if DEBUG
            print("DSSNetworkEndpoint: ", (error as NSError).debugDescription)
            #endif
        }
        request.httpMethod = method.rawValue
        return request
    }
    
    /// Returns an URLQueryItem with name ("key" as default) and NetworkClient.key as value
    func keyQueryItem(withName name: String = "key") -> URLQueryItem {
        return .init(name: name, value: key)
    }
    
    private func requestBody(boundary: String, parameters: [URLQueryItem], files: [DSSFile]) throws -> Data? {
        if (body.isEmpty && files.isEmpty) { return nil }
        var data = Data()
        guard let boundaryData = "--\(boundary)\r\n".toData else {
            throw DSSEndpointError.data(varName: "boundary: String")
        }
        guard let endBoundaryData = "--\(boundary)--\r\n".toData else {
            throw DSSEndpointError.data(varName: "endBoundary: String")
        }
        
        try parameters.forEach({
            guard let valueData: Data = .valueDataForRequestBody($0, boundary: boundaryData) else {
                throw DSSEndpointError.data(varName: "body: [URLQueryItem] (\($0)")
            }
            data.append(valueData)
        })
        
        try files.forEach({
            guard let fileData: Data = .fileDataForRequestBody($0, boundary: boundaryData) else {
                throw DSSEndpointError.data(varName: "files: [DSSFile] (\($0)")
            }
            data.append(fileData)
        })
        
        data.append(endBoundaryData)
        return data
    }
}
