//
//  ThreadSafe.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public protocol ThreadSafety {
    func execute(_ block: () -> Void)
}

@available(iOS 10.0, *)
public final class ThreadSafe: ThreadSafety {
    
    private var lock = os_unfair_lock_s()
    
    public func execute(_ block: () -> Void) {
        if !os_unfair_lock_trylock(&lock) {
            os_unfair_lock_lock(&lock)
        }
        defer { os_unfair_lock_unlock(&lock) }
        block()
    }
}

public final class ThreadSafeLegacy: ThreadSafety {
    
    private var lock = NSRecursiveLock()
    
    public func execute(_ block: () -> Void) {
        lock.lock(); defer { lock.unlock() }
        block()
    }
}

public var platformSafe: ThreadSafety {
    if #available(iOS 10.0, *) {
        return ThreadSafe()
    } else {
        return ThreadSafeLegacy()
    }
}
