//
//  URLRequestConfiguration.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

public struct Upstream<T, I> {
    let transformer: T
    let input: I
    
    public init(with transformer: T, using input: I) {
        self.transformer = transformer
        self.input = input
    }
}

public struct URLRequestConfiguration<O, E: Error>: ResourceConfiguration {
    
    public typealias Request = URLRequest
    public typealias Downstream = O

    public let expiration: ResourceExpiration
    
    private let backingRequest: () -> Request
    
    private let downstream: (Data) throws -> O
    private let error: (Data) throws -> E
    
    public init<TD: Transformer, TE: Transformer>(
        expiration: ResourceExpiration = .never,
        downstream: TD,
        error: TE,
        with request: @escaping () -> Request)
        where TD.I == Data, TD.O == O, TE.I == Data, TE.O == E {
            
            self.backingRequest = request
            self.expiration = expiration
            self.downstream = downstream.getTransformed
            self.error = error.getTransformed
    }
    
    public var request: Request {
        return backingRequest()
    }
    
    public func transform(_ result: Data) throws -> O {
        try downstream(result)
    }

    public func transformError(_ result: Data) throws -> Error {
        try error(result)
    }
    
    public func withCachePolicy(_ policy: URLRequest.CachePolicy) -> Self {
        Self.init(
            expiration: expiration,
            downstream: BlockTransformer(tranform: downstream),
            error: BlockTransformer(tranform: error)) {
                
                var request = self.backingRequest()
                request.cachePolicy = policy
                return request
        }
    }
    
    public func aggressiveConfiguration() -> URLRequestConfiguration<O, E> {
        withCachePolicy(.reloadIgnoringLocalAndRemoteCacheData)
    }
}

public extension URLRequestConfiguration {
    
    init<TU: Transformer, TD: Transformer, TE: Transformer>(
        route: URLConvertible,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeout: TimeInterval = 60.0,
        expiration: ResourceExpiration = .never,
        upstream: Upstream<TU, TU.I>,
        downstream: TD,
        error: TE)
        where TU.O == Data, TD.I == Data, TD.O == O, TE.I == Data, TE.O == E {
                        
            self.init(expiration: expiration, downstream: downstream, error: error) {
                var request = URLRequest(url: route.asUrl, cachePolicy: cachePolicy, timeoutInterval: timeout)
                request.httpMethod = method.rawValue
                request.allHTTPHeaderFields = headers
                if method != .get {
                    request.httpBody = try? upstream.transformer.getTransformed(with: upstream.input)
                }
                return request
            }
    }
    
    init(route: URLConvertible,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeout: TimeInterval = 60.0,
        expiration: ResourceExpiration = .never) {
        
        self.init(expiration: expiration, downstream: EmptyTransformer(), error: EmptyTransformer()) {
            var request = URLRequest(url: route.asUrl, cachePolicy: cachePolicy, timeoutInterval: timeout)
            request.httpMethod = method.rawValue
            request.allHTTPHeaderFields = headers
            return request
        }
    }
}

public extension URLRequestConfiguration where O: Decodable, E: Decodable {
    
    init<TU: Transformer>(
        route: URLConvertible,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeout: TimeInterval = 60.0,
        expiration: ResourceExpiration = .never,
        upstream: Upstream<TU, TU.I>)
        where TU.O == Data {
            
            self.init(route: route,
                      method: method,
                      headers: headers,
                      cachePolicy: cachePolicy,
                      timeout: timeout,
                      expiration: expiration,
                      upstream: upstream,
                      downstream: DecodableTransformer(),
                      error: DecodableTransformer())
    }
    
    init<I: Encodable>(
        route: URLConvertible,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeout: TimeInterval = 60.0,
        expiration: ResourceExpiration = .never,
        body: I,
        encoder: JSONEncoder = JSONEncoder()) {
        
        self.init(route: route,
                  method: method,
                  headers: headers,
                  cachePolicy: cachePolicy,
                  timeout: timeout,
                  expiration: expiration,
                  upstream: Upstream(with: EncodableTransformer(encoder: encoder), using: body),
                  downstream: DecodableTransformer(),
                  error: DecodableTransformer())
    }
}
