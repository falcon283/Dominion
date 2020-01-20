//
//  FakeHTTPTransport.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public typealias HTTPTransportResponse = (Data?, HTTPURLResponse?, Error?)

enum FakeHTTPTransportError: Error {
    case responseNotFound
    case genericError
}

public class FakeHTTPTransport: HTTPTransport {
    
    private let safe: ThreadSafety = platformSafe
    
    private var responses: [Int: HTTPTransportResponse] = [:]
    var interceptor: ((Data?, FakeURLResponse?, Error?) -> Void)?
    
    public var latency: DispatchTimeInterval
    public var latencyVariance: DispatchTimeInterval
    
    public init(latency: DispatchTimeInterval, latencyVariance: DispatchTimeInterval) {
        self.latency = latency
        self.latencyVariance = latencyVariance
    }
    
    public func addFakeResponse(_ response: HTTPTransportResponse, for request: URLRequest) {
        safe.execute {
            responses[request.fakeHash] = response
        }
    }
    
    public func cleanup() {
        safe.execute {
            responses = [:]
        }
    }
    
    public func task(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> ResourceTask {
        let response = responses[request.fakeHash]
        
        return FakeTransportResourceTask(on: .main, latency: latency, variance: latencyVariance) { [weak self] in
            if let r = response {
                let fakeResponse = FakeURLResponse(originalURLRequest: request, response: r.1)
                self?.interceptor?(r.0, fakeResponse, r.2)
                completion(r.0, r.1, r.2)
            } else {
                self?.interceptor?(nil, nil, FakeHTTPTransportError.responseNotFound)
                completion(nil, nil, FakeHTTPTransportError.responseNotFound)
            }
        }
    }
}

private extension URLRequest {
    
    var fakeHash: Int {
        var hasher = Hasher()
        hasher.combine(url)
        self.httpBody.map { hasher.combine($0) }
        self.httpMethod.map { hasher.combine($0) }
        return hasher.finalize()
    }
}

public class FakeURLResponse: URLResponse {
    
    public let originalURLRequest: URLRequest?
    public let urlResponse: URLResponse?
    
    init(originalURLRequest: URLRequest, response: URLResponse?) {
        self.originalURLRequest = originalURLRequest
        self.urlResponse = response
        super.init(url: originalURLRequest.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class FakeTransportResourceTask: ResourceTask {
    
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
