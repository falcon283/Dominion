//
//  ThreadSafe.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// Thread safety Protocol
public protocol ThreadSafety {
    /// Execute a task in a thread safe manner.
    /// - Parameter block: The task to execute.
    func execute(_ block: () -> Void)
}

@available(iOS 10.0, *)
/// This object use an `os_unfair_lock` internally to handle the resource exclusive access.
public final class ThreadSafe: ThreadSafety {
    
    private var lock = os_unfair_lock_s()
    
    public init() { }
    
    public func execute(_ block: () -> Void) {
        if !os_unfair_lock_trylock(&lock) {
            os_unfair_lock_lock(&lock)
        }
        defer { os_unfair_lock_unlock(&lock) }
        block()
    }
}

public final class ThreadSafeLegacy: ThreadSafety {
    
    private var lock = NSLock()
    
    public init() { }
    
    public func execute(_ block: () -> Void) {
        lock.lock(); defer { lock.unlock() }
        block()
    }
}


/// A legacy ThreadSafe executor that uses an `NSRecursiveLock` internally to handle the resource exclusive access.
public final class RecursiveThreadSafe: ThreadSafety {
    
    private var lock = NSRecursiveLock()
    
    public init() { }
    
    public func execute(_ block: () -> Void) {
        lock.lock(); defer { lock.unlock() }
        block()
    }
}
    
public func threadSafe() -> ThreadSafety {
    if #available(iOS 10.0, *) {
        return ThreadSafe()
    } else {
        return ThreadSafeLegacy()
    }
}

public func recursiveThreadSafe() -> ThreadSafety {
    RecursiveThreadSafe()
}
