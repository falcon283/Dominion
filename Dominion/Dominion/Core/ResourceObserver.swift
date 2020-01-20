//
//  ResourceObserver.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public typealias ObservationCallback<T> = (Result<T, Error>) -> Void

private class Token { }

public protocol CancellationToken: class { }

public extension CancellationToken {
    
    func store(in array: inout [CancellationToken], using safe: ThreadSafety = platformSafe) {
        safe.execute {
            array.append(self)
        }
    }
}

public class DeinitCancellationToken: CancellationToken {
    
    private let block: () -> Void
    
    public init(block: @escaping () -> Void) {
        self.block = block
    }
    
    deinit {
        block()
    }
}

public class NoOpCancellationToken: CancellationToken { }

public struct ResourceObserver<T> {
    
    let id = ObjectIdentifier(Token())
    private let update: ObservationCallback<T>
    private let queue = OperationQueue.current ?? OperationQueue.main
    
    public init(block: @escaping ObservationCallback<T>) {
        self.update = block
        self.queue.name = "it.gtrabucco.resource-observer"
        self.queue.maxConcurrentOperationCount = 1
        self.queue.isSuspended = false
    }
    
    func emit(_ result: Result<T, Error>) {
        queue.addOperation {
            self.update(result)
        }
    }
}
