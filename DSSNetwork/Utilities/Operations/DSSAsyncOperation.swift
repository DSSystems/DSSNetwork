//
//  DSSAsyncOperation.swift
//  DSSNetwork
//
//  Created by David on 01/04/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation

open class DSSAsyncOperation: Operation {
    public enum State: String {
        case ready, executing, finished
        
        fileprivate var keyPath: String {
            return "is" + rawValue.capitalized
        }
    }
    
    open var state: State = .ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    
    override open var isReady: Bool { super.isReady && state == .ready }
    
    override open var isExecuting: Bool { state == .executing }
    
    override open var isFinished: Bool { state == .finished }
    
    override open var isAsynchronous: Bool { true }
    
    override open func start() {
        guard !isCancelled else {
            state = .finished
            return
        }
        
        state = .executing
        main()
    }
    
    override open func cancel() {
        state = .finished
    }
}
