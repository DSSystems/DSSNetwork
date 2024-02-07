//
//  Tools.swift
//  DSSNetwork
//
//  Created by David on 10/04/21.
//  Copyright © 2021 DS_Systems. All rights reserved.
//

import Foundation

//public func map<Model, NewModel, E: Error>(_ transform: (Model) throws -> NewModel) rethrows  -> ResultBlock<NewModel, E> {
//    return { _ in
//        
//    }
//}

public extension URLRequest {
    func printStringBody() {
        guard let data = httpBody else {
            dump(["URLRequest": "httpBody is nil."])
            return
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            dump(["URLRequest": "Data is not a String"])
            return
        }
        
        dump(string)
    }
}
