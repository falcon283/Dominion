//
//  FakeHTTPTransport.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public typealias HTTPTransportResponse = (Data?, URLResponse?, Error?)

enum FakeHTTPTransportError: Error {
    case responseNotFound
}

public class FakeHTTPTransport: HTTPTransport {
    
    private let safe: ThreadSafety = platformSafe
    
    private var responses: [URLRequest: HTTPTransportResponse] = [:]
    
    public var latency: DispatchTimeInterval
    public var latencyVariance: DispatchTimeInterval
    
    public init(latency: DispatchTimeInterval, latencyVariance: DispatchTimeInterval) {
        self.latency = latency
        self.latencyVariance = latencyVariance
    }
    
    public func addFakeResponse(_ response: HTTPTransportResponse, for request: URLRequest) {
        safe.execute {
            responses[request] = response
        }
    }
    
    public func cleanup() {
        safe.execute {
            responses = [:]
        }
    }
    
    public func task(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> ResourceTask {
        let response = responses[request]
        return DispatchWorkItemTask(on: .main, latency: latency, variance: latencyVariance) {
            if let r = response {
                completion(r.0, r.1, r.2)
            } else {
                completion(nil, nil, FakeHTTPTransportError.responseNotFound)
            }
        }
    }
}

public class DispatchWorkItemTask: ResourceTask {
    
    private let task: () -> Void
    private let queue: DispatchQueue
    private let latency: DispatchTimeInterval
    private let variance: DispatchTimeInterval

    public init(on queue: DispatchQueue, latency: DispatchTimeInterval, variance: DispatchTimeInterval, task: @escaping () -> Void) {
        self.queue = queue
        self.latency = latency
        self.variance = variance
        self.task = task
    }
    
    private var currentItem: DispatchWorkItem?
    
    public func suspend() {
        cancel()
    }
    
    public func resume() {
        let item = DispatchWorkItem(block: task)
        currentItem = item
        
        queue.asyncAfter(deadline: .now() + latency + variance.randomVariance, execute: item)
    }
    
    public func cancel() {
        currentItem?.cancel()
    }
    
    public var progress: Double { return 0 }
}

private extension DispatchTimeInterval {
    
    var randomVariance: DispatchTimeInterval {
        switch self {
        case .seconds(let s):
            return .seconds(Int.random(in: -s...s))
        case .milliseconds(let m):
            return .milliseconds(Int.random(in: -m...m))
        case .microseconds(let m):
            return .microseconds(Int.random(in: -m...m))
        case .nanoseconds(let n):
            return .nanoseconds(Int.random(in: -n...n))
        case .never:
            return self
        @unknown default:
            return self
        }
    }
}
