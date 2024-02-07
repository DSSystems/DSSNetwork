//
//  DSSNetworkClient.swift
//  DSSNetwork
//
//  Created by David on 10/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import UIKit

public enum DSSNetworkResult<T: Decodable, U: Decodable> where U: DSSServerErrorModel {
    case success(response: T)
    case serverError(errorResponse: U)
    case failure(error: Error)
}

public enum DSSNetworkClientTaskResult<T: Decodable> {
    case success(task: URLSessionDataTask)
    case cachedValue(value: T)
}

public enum DSSNetworkClientTestTaskResult {
    case success(task: URLSessionDataTask)
    case cachedValue(value: Dictionary<String, Any>)
}

public protocol DSSNetworkClient { 
    static var baseUrl: String { get }
    static var key: String { get }
    
    var session: URLSession { get }
    
    func sharedCacheManager() -> DSSNetworkCacheManager?
}

public typealias ResultBlock<Model, ErrorObject: Error> = (Result<Model, ErrorObject>) -> Void
public typealias NetworkResultBlock<Model: Decodable, ErrorModel: DSSServerErrorModel & Decodable> = (DSSNetworkResult<Model, ErrorModel>) -> Void

public extension DSSNetworkClient {
    static var key: String { return "N/A" }
    
    var session: URLSession { return URLSession.shared }
    
    func sharedCacheManager() -> DSSNetworkCacheManager? { return nil }
    
    func taskRequest<T: Codable, Endpoint: DSSNetworkEndpoint>(
        endpoint: Endpoint,
        completion: @escaping ResultBlock<T, Error>
    ) -> DSSNetworkClientTaskResult<T> {
        taskRequest(
            with: endpoint.request,
            decodingStrategy: endpoint.jsonDecoderStrategy,
            cacheTimeInterval: endpoint.cacheInterval,
            completion: completion
        )
    }
    
    func taskRequest<T: Codable>(
        with request: URLRequest,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        cacheTimeInterval: TimeInterval = 0,
        completion: @escaping ResultBlock<T, Error>
    ) -> DSSNetworkClientTaskResult<T> {
        if cacheTimeInterval > 0, let value: T = cachedValue(for: request) { return .cachedValue(value: value) }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error { return completion(.failure(error)) }
            
            guard let httpResponse = response?.http, 200..<300 ~= httpResponse.statusCode else {
                let code: Int = response?.http?.statusCode ?? 0
                let statusError = DSSNetworkClientError.badResponse(code: code)
                return completion(.failure(statusError))
            }
                        
            guard let data = data else {
                let unwrapError = DSSNetworkClientError.unwrap(varName: "Data")
                return completion(.failure(unwrapError))
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = decodingStrategy
            
            do {
                let value = try decoder.decode(T.self, from: data)
                if cacheTimeInterval > 0 {
                    self.sharedCacheManager()?.cache(networkObject: value, for: request, timeInterval: cacheTimeInterval)
                }
                completion(.success(value))
            } catch let decodingError as DecodingError {
                switch decodingError {
                case .dataCorrupted(_):
                    let content = String(data: data, encoding: .utf8)
                    let description = (decodingError as NSError).debugDescription
                    completion(.failure(DSSNetworkClientError.decoding(description: description, content: content)))
                case .keyNotFound(/*let codingKey*/_, let context):
                    let description = (decodingError as NSError).debugDescription
                    completion(.failure(DSSNetworkClientError.decoding(description: description, content: "\(context)")))
                default:
                    completion(.failure(decodingError))
                }
            } catch let decoderError {
                completion(.failure(decoderError))
            }
        }
        return .success(task: task)
    }
        
    func call<T: Codable, Endpoint: DSSNetworkEndpoint>(endpoint: Endpoint, completion: @escaping ResultBlock<T, Error>) {
        call(with: endpoint.request,
             decodingStrategy: endpoint.jsonDecoderStrategy,
             cacheTimeInterval: endpoint.cacheInterval,
             completion: completion)
    }
    
    func call(
        with request: URLRequest,
        cacheTimeInterval: TimeInterval = 0,
        completion: @escaping ResultBlock<Data, Error>
    ) {
//        let taskResult = taskRequest(with: request, cacheTimeInterval: cacheTimeInterval, completion: completion)
//        switch taskResult {
//        case .success(let task): task.resume()
//        case .cachedValue(let value): completion(.success(value))
//        }
        if let data: Data = cachedValue(for: request) { return completion(.success(data)) }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error { return completion(.failure(error)) }
            
            guard let httpResponse = response?.http, 200..<300 ~= httpResponse.statusCode else {
                let code: Int = response?.http?.statusCode ?? 0
                let statusError = DSSNetworkClientError.badResponse(code: code)
                return completion(.failure(statusError))
            }
            
            guard let data = data else {
                let unwrapError = DSSNetworkClientError.unwrap(varName: "Data")
                return completion(.failure(unwrapError))
            }
            
            if cacheTimeInterval > 0 { sharedCacheManager()?.cache(networkObject: data, for: request, timeInterval: cacheTimeInterval) }
            
            completion(.success(data))
        }
        task.resume()
    }
    
    func call<T: Codable>(with request: URLRequest, decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys, cacheTimeInterval: TimeInterval = 0, completion: @escaping ResultBlock<T, Error>) {
        let taskResult = taskRequest(with: request, cacheTimeInterval: cacheTimeInterval, completion: completion)
        switch taskResult {
        case .success(let task): task.resume()
        case .cachedValue(let value): completion(.success(value))
        }
    }
    
    func taskRequest<T: Codable, U: Decodable, Endpoint: DSSNetworkEndpoint>(endpoint: Endpoint, completion: @escaping NetworkResultBlock<T, U>) -> DSSNetworkClientTaskResult<T> {
        taskRequest(
            with: endpoint.request,
            decodingStrategy: endpoint.jsonDecoderStrategy,
            cacheTimeInterval: endpoint.cacheInterval,
            completion: completion
        )
    }
    
    func taskRequest<T: Codable, U: Decodable>(
        with request: URLRequest,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        cacheTimeInterval: TimeInterval = 0,
        completion: @escaping NetworkResultBlock<T, U>
    ) -> DSSNetworkClientTaskResult<T> {
        if cacheTimeInterval > 0, let value: T = cachedValue(for: request) { return .cachedValue(value: value) }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                return completion(.failure(error: error))
            }
            
            guard let httpResponse = response?.http, 200..<300 ~= httpResponse.statusCode else {
                let code: Int = response?.http?.statusCode ?? 0
                let statusError = DSSNetworkClientError.badResponse(code: code)
                return completion(.failure(error: statusError))
            }
            
            guard let data = data else {
                let unwrapError = DSSNetworkClientError.unwrap(varName: "Data")
                return completion(.failure(error: unwrapError))
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = decodingStrategy
            
            if let errorResponse = try? decoder.decode(U.self, from: data), errorResponse.didFindError {
                return completion(.serverError(errorResponse: errorResponse))
            }
            
            do {
                let response = try decoder.decode(T.self, from: data)
                if cacheTimeInterval > 0 {
                    self.sharedCacheManager()?.cache(networkObject: response, for: request, timeInterval: cacheTimeInterval)
                }
                completion(.success(response: response))
            } catch let decodingError as DecodingError {
                switch decodingError {
                case .dataCorrupted(_):
                    let content = String(data: data, encoding: .utf8)
                    let description = (decodingError as NSError).debugDescription
                    completion(.failure(error: DSSNetworkClientError.decoding(description: description, content: content)))
                default:
                    completion(.failure(error: decodingError))
                }
            } catch let decoderError {
                completion(.failure(error: decoderError))
            }
        }
        return .success(task: task)
    }
    
    func call<T: Codable, U: Decodable, Endpoint: DSSNetworkEndpoint>(endpoint: Endpoint, completion: @escaping NetworkResultBlock<T, U>) {
        call(
            with: endpoint.request,
            decodingStrategy: endpoint.jsonDecoderStrategy,
            cacheTimeInterval: endpoint.cacheInterval,
            completion: completion
        )
    }
    
    func call<T: Codable, U: Decodable>(
        with request: URLRequest,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        cacheTimeInterval: TimeInterval = 0,
        completion: @escaping NetworkResultBlock<T, U>
    ) {
        let taskResult = taskRequest(
            with: request,
            decodingStrategy: decodingStrategy,
            cacheTimeInterval: cacheTimeInterval,
            completion: completion
        )
        switch taskResult {
        case .success(let task): task.resume()
        case .cachedValue(let value): completion(.success(response: value))
        }
    }
    
    func requestTest(with request: URLRequest, completion: @escaping (Result<Dictionary<String, Any>, Error>) -> Void) {
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error { return completion(.failure(error)) }
            
            guard let httpResponse = response?.http, 200..<300 ~= httpResponse.statusCode else {
                let code: Int = response?.http?.statusCode ?? 0
                let statusError = DSSNetworkClientError.badResponse(code: code)
                return completion(.failure(statusError))
            }
            
            guard let data = data else {
                let unwrapError = DSSNetworkClientError.unwrap(varName: "Data")
                return completion(.failure(unwrapError))
            }
            
            if let dataString = String(data: data, encoding: .utf8) {
                #if DEBUG
                print("Response: \n\(dataString)")
                #endif
            }
            
            do {
                guard let value = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String, Any> else {
                    throw DSSNetworkClientError.unwrap(varName: "value: Dictionary<String, Any>")
                }
                completion(.success(value))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func cachedValue<T: Codable>(for request: URLRequest) -> T? {
        guard let manager = sharedCacheManager() else { return nil }
        guard let object: T = manager.networkObject(for: request) else { return nil }
        return object
    }
}
