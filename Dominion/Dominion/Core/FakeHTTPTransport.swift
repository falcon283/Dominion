//
//  FakeHTTPTransport.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public typealias HTTPTransportResponse = (Data?, HTTPURLResponse?, Error?)

/// Possible Errors raised by the FakeHTTPTransport due to missing or not handled mocked data.
enum FakeHTTPTransportError: Error {
    
    /// The response for the given request is not found.
    case responseNotFound
    
    /// Generic error.
    case genericError
}

/// A Fake HTTPTransport suitable for Unit Testing.
public class FakeHTTPTransport: HTTPTransport {
    
    private let safe: ThreadSafety = platformSafe
    
    private var responses: [Int: HTTPTransportResponse] = [:]
    var interceptor: ((Data?, FakeURLResponse?, Error?) -> Void)?
    
    /// The latency used to emit a response
    public var latency: DispatchTimeInterval
    
    /// The latency variance used to simulate a non constant network latency
    public var latencyVariance: DispatchTimeInterval
    
    /// Designated initializer
    /// - Parameters:
    ///   - latency: The base latency of the Transport
    ///   - latencyVariance: The latency variance used to mimic a non constant latency
    public init(latency: DispatchTimeInterval, latencyVariance: DispatchTimeInterval) {
        self.latency = latency
        self.latencyVariance = latencyVariance
    }
    
    /// Store a fake response for the given request. Response are stored by request and request are identified uniquely by its own URL, Method and Body.
    /// - Parameters:
    ///   - response: The response to return for a particular request.
    ///   - request: The request to associate with the particular response.
    public func addFakeResponse(_ response: HTTPTransportResponse, for request: URLRequest) {
        safe.execute {
            responses[request.fakeHash] = response
        }
    }
    
    /// Cleanup all the mocket response stored.
    public func cleanup() {
        safe.execute {
            responses = [:]
        }
    }
    
    public func task(with request: URLRequest,
                     completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) -> ResourceTask {
        
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
    
    /// Hash used to couple the request and the response and return the particular response when needed.
    var fakeHash: Int {
        var hasher = Hasher()
        hasher.combine(url)
        self.httpBody.map { hasher.combine($0) }
        self.httpMethod.map { hasher.combine($0) }
        return hasher.finalize()
    }
}

/// An URLResponse to wrap and inspect the original request and the
public class FakeURLResponse: URLResponse {
    
    /// The request for the mocked response.
    public let originalURLRequest: URLRequest?
    
    /// The mocked response for the given request.
    public let urlResponse: URLResponse?
    
    /// Designated initializer
    /// - Parameters:
    ///   - originalURLRequest: The network request coupled with the mocked response.
    ///   - response: The mocked response.
    init(originalURLRequest: URLRequest, response: URLResponse?) {
        self.originalURLRequest = originalURLRequest
        self.urlResponse = response
        super.init(url: originalURLRequest.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/// A ResourceTask suitable for a mocked HTTPTransport
public final class FakeTransportResourceTask: ResourceTask {
    
    private let task: () -> Void
    private let queue: DispatchQueue
    private let latency: DispatchTimeInterval
    private let variance: DispatchTimeInterval
    
    /// Designated initializer
    /// - Parameters:
    ///   - queue: The queue used for the responses.
    ///   - latency: The latency to use for the responses.
    ///   - variance: The latency variance to use for the responses.
    ///   - task: The task to execute on resume.
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
