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

/// An opaque object suitable for memory management of the observers.
public protocol CancellationToken: class { }

public extension CancellationToken {
    
    /// Add the cancellation token to a collection of tokens.
    /// - Parameters:
    ///   - array: The array to use as storage for the token
    ///   - safe: The ThreadSafe Object to use to avoid memory corruption in multithreading execution.
    func store(in array: inout [CancellationToken], using safe: ThreadSafety = platformSafe) {
        safe.execute {
            array.append(self)
        }
    }
}

/// A simple Cancellation token that execute an action when deallocated.
public class DeinitCancellationToken: CancellationToken {
    
    private let block: () -> Void
    
    /// Designated initializer
    /// - Parameter block: The closure to run when the Token gets deallocated
    public init(block: @escaping () -> Void) {
        self.block = block
    }
    
    deinit {
        block()
    }
}

/// No Operation cancellation token.
public class NoOpCancellationToken: CancellationToken { }

/// The resource observer is a closure wrapper used to emit the given result. The emission is performed on the Operation Queue of the given thread, if available,
/// or on the main queue if not. Resource Observer emission is Threadsafe.
public struct ResourceObserver<T> {
    
    let id = ObjectIdentifier(Token())
    private let update: ObservationCallback<T>
    private let queue = OperationQueue.current ?? OperationQueue.main
    
    /// Designated initializer.
    /// - Parameter block: The closure to run when emission is requested
    public init(block: @escaping ObservationCallback<T>) {
        self.update = block
        self.queue.name = "it.gtrabucco.resource-observer"
        self.queue.maxConcurrentOperationCount = 1
        self.queue.isSuspended = false
    }
    
    /// Emit a result. The emission is performed on the Operation Queue of the thread used to allocate the Observer, if available,
    /// or on the main queue if not.
    /// - Parameter result: The result to emit.
    func emit(_ result: Result<T, Error>) {
        queue.addOperation {
            self.update(result)
        }
    }
}
