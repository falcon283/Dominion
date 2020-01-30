//
//  Retry.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 21/02/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public typealias RetryClosure = (UInt, @escaping () -> Void) -> CancellationToken?

public typealias RetryTime = (UInt) -> TimeInterval

/// A TimeFucntion to use for retry Purpose.
public enum RetryTimeFunction {
    
    /// Execute the retry in constant time.
    case constant(_ delay: TimeInterval)
    
    /// Execute the retry in linear time.
    case linear(_ delay: TimeInterval)
    
    /// Execute the retry in quadratic time.
    case quadratic(_ delay: TimeInterval)
    
    /// Execute the retry in cubic time.
    case cubic(_ delay: TimeInterval)
    
    /// Execute the retry in exponencial time (Base 2).
    case exponential(_ delay: TimeInterval)
    
    /// Execute the retry in fibonacci time.
    case fibonacci(_ delay: TimeInterval)
}

extension RetryTimeFunction {
    
    var timeFunction: RetryTime {
        switch self {
        case .constant(let delay):
            return Self.timeConstant(delay)
        case .linear(let delay):
            return Self.timeLinear(delay)
        case .quadratic(let delay):
            return Self.timeQuadratic(delay)
        case .cubic(let delay):
            return Self.timeCubic(delay)
        case .exponential(let delay):
            return Self.timeExponential(delay)
        case .fibonacci(let delay):
            return Self.timeFibonacci(delay)
        }
    }
    
    private static func timeConstant(_ delay: TimeInterval) -> RetryTime {
        return { _ in delay }
    }
    
    private static func timeLinear(_ delay: TimeInterval) -> RetryTime {
        return { attempt in TimeInterval(attempt) * delay }
    }
    
    private static func timeQuadratic(_ delay: TimeInterval) -> RetryTime {
        return { attempt in TimeInterval(attempt * attempt) * delay }
    }
    
    private static func timeCubic(_ delay: TimeInterval) -> RetryTime {
        return { attempt in TimeInterval(attempt * attempt * attempt) * delay }
    }
    
    private static func timeExponential(_ delay: TimeInterval) -> RetryTime {
        return { attempt in exp2(Double(attempt)) * delay }
    }
    
    private static func timeFibonacci(_ delay: TimeInterval) -> RetryTime {
        
        func fibonacci(_ limit: UInt) -> UInt {
            switch limit {
            case 0:
                return 0
            case 1:
                return 1
            default:
                return fibonacci(limit - 1) + fibonacci(limit - 2)
            }
        }
        
        return { attempt in TimeInterval(fibonacci(attempt)) * delay }
    }
}
