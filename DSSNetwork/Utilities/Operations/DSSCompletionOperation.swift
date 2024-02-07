//
//  DSSCompletionOperation.swift
//  DSSNetwork
//
//  Created by David on 09/05/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation

open class DSSCompletionOperation<Dependency: Operation>: DSSAsyncOperation {
    public override func main() {
        guard let dependency = dependencies.first(where: { $0 is Dependency }) as? Dependency else {
            fatalError("Depencendy of type \(NSStringFromClass(Dependency.self)) not found")
        }
        main(with: dependency)
    }
    
    open func main(with operation: Dependency) {
        fatalError("You should override this method!")
    }
}

open class DSSHTTPRequestCompletionOperation<PrevOperation: Operation, DataModel: Decodable, ErrorModel: DSSServerErrorModel & Decodable>: DSSCompletionOperation<PrevOperation> {
    
    public internal(set) var result: DSSNetworkOperationResult<DataModel, ErrorModel> = .operationFailure(error: .unknown)
    
    public var decoder: JSONDecoder = JSONDecoder()
    
    private var networkHandler: ((PrevOperation) -> DSSNetworkMetadata)!
    private let completion: (DSSNetworkOperationResult<DataModel, ErrorModel>) -> Void
    
    public init(networkHandler: @escaping (PrevOperation) -> DSSNetworkMetadata) {
        self.networkHandler = networkHandler
        self.completion = { _ in }
        super.init()
    }
    
    public init(networkHandler: @escaping (PrevOperation) -> DSSNetworkMetadata,
                completion: @escaping (DSSNetworkOperationResult<DataModel, ErrorModel>) -> Void) {
        self.networkHandler = networkHandler
        self.completion = completion
        super.init()
    }
    
    open override func main(with operation: PrevOperation) {
        let networkResult = networkHandler(operation)
        networkHandler = nil
        
        switch networkResult {
        case .failure(error: let error):
            if let opError = error as? DSSOperationError {
                result = .operationFailure(error: opError)
            } else if let nError = error as? DSSNetworkClientError {
                result = .failure(error: nError)
            } else {
                result = .failure(error: error)
            }
            
            self.completion(self.result)
            self.state = .finished
            
//            DispatchQueue.main.async {
//                self.completion(self.result)
//                self.state = .finished
//            }
        case .success(session: let session, request: let request):
            let task = session.dataTask(with: request) { [weak self] (data, response, error) in
                guard let self = self else { return }
                self.result = .init(data: data, response: response, error: error, decoder: self.decoder)
                
                self.completion(self.result)
                self.state = .finished
                
//                DispatchQueue.main.async {
//                    self.completion(self.result)
//                    self.state = .finished
//                }
            }
            
            task.resume()
        }
    }
}
