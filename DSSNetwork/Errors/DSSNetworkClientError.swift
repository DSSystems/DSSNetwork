//
//  DSSNetworkClientError.swift
//  DSSNetwork
//
//  Created by David on 13/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

fileprivate func localizedString(_ string: String) -> String {
    return NSLocalizedString(string, bundle: Bundle.main, comment: "")
}

fileprivate extension String {
    var locallyLocalized: String {
        NSLocalizedString(self, bundle: Bundle(for: DSSTools.self), comment: "")
    }
}

public enum DSSNetworkClientError: DSSNError {
    case badResponse(code: Int)
    case unwrap(varName: String)
    case casting(varName: String)
    case external(description: String)
    case decoding(description: String, content: String?)
    case `internal`(error: Error)
    case unknown
    
    public var localizedDescription: String {
        switch self {
        case .badResponse(let code):
            let description = "LOCAL:ServerReturnedAnInvalidStatusCode".locallyLocalized
            return "\(description): \(code)."
        case .unwrap(let varName):
            let description = "LOCAL:Failed to unwrap variable".locallyLocalized
            return "\(description): \(varName)"
        case .casting(let varName):
            let description = "LOCAL:Failed to cast variable".locallyLocalized
            return "\(description): \(varName)"
        case .external(let description):
            return description
        case .decoding(let description, let content):
            guard let content = content else { return "LOCAL:InvalidResponse.".locallyLocalized }
            return "\(description): \(content)"
        case .internal(let error): return error.localizedDescription
        case .unknown: return "LOCAL:Unknown".locallyLocalized
        }
    }
    
    public var code: Int {
        switch self {
        case .internal:     return 0
        case .badResponse:  return 1
        case .unwrap:       return 2
        case .casting:      return 3
        case .external:     return 4
        case .decoding:     return 5
        
        case .unknown:      return -2
        }
    }
    
    public var nsError: NSError {
        let domain = String(describing: type(of: self))
        let error = NSError(domain: domain,
                            code: code,
                            userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        return error
    }
}
