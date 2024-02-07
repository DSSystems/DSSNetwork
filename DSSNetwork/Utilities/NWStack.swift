
//
//  NWStack.swift
//  DSSNetwork
//
//  Created by David on 01/04/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation

class NWNode<T> {
    let object: T
    var next: NWNode<T>? = nil
    
    init(_ object: T) {
        self.object = object
    }
}

class NWStack<T> {
    public typealias Element = T
    
    var top: NWNode<T>?
    
    private var nodeCount: Int = 0
    
    var numberOfNodes: Int { return nodeCount }
    
    public init() { }
    
    public func push(_ object: T) {
        let newNode: NWNode<T> = .init(object)
        newNode.next = top
        nodeCount += 1
        top = newNode
    }
    
    public func pop() -> T? {
        defer {
            top = top?.next
            nodeCount -= 1
        }
        
        return top?.object
    }
        
    public func peek() -> T? {
        return top?.object
    }
}
