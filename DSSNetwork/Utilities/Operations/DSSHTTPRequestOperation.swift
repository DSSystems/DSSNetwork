//
//  DSSHTTPRequestOperation.swift
//  DSSNetwork
//
//  Created by David on 05/05/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation

public enum DSSNetworkMetadata {
    case failure(error: Error)
    case success(session: URLSession, request: URLRequest)
}

public enum DSSOperationError: Error {
    case missingDependency(type: AnyObject)
    case missingData
    case dependencyError
    case badResponse(status: Int)
    case unwrap(varName: String)
    case unknown
    
    public var localizedDescription: String {
        switch self {
        case .missingDependency(type: let type):
            return "Missing dependency: \(String(reflecting: type))"
        case .missingData:
            return "The data returned by the server is no valid"
        case .dependencyError:
            return "An error ocurred in dependency operation"
        case .badResponse(let status):
            return "Bad response: \(status)"
        case .unwrap(varName: let varName):
            return "Failed to unwrap \(varName)"
        case .unknown:
            return "Unknown"
        }
    }
}

public enum DSSOperationNilErrorModel: DSSServerErrorModel & Decodable {
    public var didFindError: Bool { false }
    public init(from decoder: Decoder) throws {
        fatalError("\(String(reflecting: Self.self)) is a placeholder to represent the error model object, it should not be initialized.")
    }
}

public enum DSSNetworkOperationResult<DataModel: Decodable, ErrorModel: DSSServerErrorModel & Decodable> {
    case success(response: DataModel)
    case failure(error: Error)
    case serverError(errorResponse: ErrorModel)
    case operationFailure(error: DSSOperationError)
    
    init(data: Data?, response: URLResponse?, error: Error?, decoder: JSONDecoder) {
        if let error = error {
            self = .failure(error: error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            self = .operationFailure(error: .unwrap(varName: "response: HTTPURLResponse"))
            return
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            self = .operationFailure(error: .badResponse(status: httpResponse.statusCode))
            return
        }
        
        guard let data = data else {
            self = .operationFailure(error: .missingData)
            return
        }
        
        if ErrorModel.self != DSSOperationNilErrorModel.self,
            let errorResponse = try? decoder.decode(ErrorModel.self, from: data),
            errorResponse.didFindError {
            self = .serverError(errorResponse: errorResponse)
            return
        }
        
        do {
            let response = try decoder.decode(DataModel.self, from: data)
            self = .success(response: response)
        } catch {
            self = .failure(error: error)
        }
    }
}

open class DSSHTTPRequestOperation<DataModel: Decodable, ErrorModel: DSSServerErrorModel & Decodable>: DSSAsyncOperation {
    public internal(set) var result: DSSNetworkOperationResult<DataModel, ErrorModel> = .operationFailure(error: .unknown)
    
    private var task: URLSessionDataTask!
    
    public var decoder = JSONDecoder()
    
    public init(session: URLSession, request: URLRequest) {
        super.init()
        
        task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let self = self else { return }
            self.result = .init(data: data, response: response, error: error, decoder: self.decoder)
            self.state = .finished
        })
    }
    
    public init(session: URLSession,
                request: URLRequest,
                completion: @escaping (DSSNetworkOperationResult<DataModel, ErrorModel>) -> Void) {
        
        super.init()
        
        task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let self = self else { return }
            self.result = .init(data: data, response: response, error: error, decoder: self.decoder)
            completion(self.result)
            self.state = .finished
        })
    }
    
    override open func main() { task.resume() }
}
