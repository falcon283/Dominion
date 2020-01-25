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
    public let identifier: String
    
    private let backingRequest: () -> Request
    
    private let downstream: (Data?) throws -> O
    private let error: (Data?) throws -> E
    
    public init<TD: Transformer, TE: Transformer>(
        identifier: String,
        expiration: ResourceExpiration = .never,
        downstream: TD,
        error: TE,
        with request: @escaping () -> Request)
        where TD.I == Data, TD.O == O, TE.I == Data, TE.O == E {
            
            self.identifier = identifier
            self.backingRequest = request
            self.expiration = expiration
            self.downstream = downstream.getTransformed
            self.error = error.getTransformed
    }
    
    public init<TU: Transformer, TD: Transformer, TE: Transformer>(
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
            
            let identifier = [route.asUrl.host ?? "emptyHost",
                              route.asUrl.path,
                              method.rawValue]
                .joined(separator: "-")
            
            self.init(identifier: identifier, expiration: expiration, downstream: downstream, error: error) {
                var request = URLRequest(url: route.asUrl, cachePolicy: cachePolicy, timeoutInterval: timeout)
                request.httpMethod = method.rawValue
                request.allHTTPHeaderFields = headers
                if method != .get {
                    request.httpBody = try? upstream.transformer.getTransformed(with: upstream.input)
                }
                return request
            }
    }
    
    public var request: Request {
        return backingRequest()
    }
    
    public func transform(_ result: Data?) throws -> O {
        try downstream(result)
    }
    
    public func transformError(_ result: Data?) throws -> Error {
        try error(result)
    }
    
    public func withCachePolicy(_ policy: URLRequest.CachePolicy) -> Self {
        Self.init(
            identifier: identifier,
            expiration: expiration,
            downstream: BlockTransformer(tranform: downstream),
            error: BlockTransformer(tranform: error)) {
                
                var request = self.backingRequest()
                request.cachePolicy = policy
                return request
        }
    }
    
    public func aggressiveConfiguration() -> URLRequestConfiguration<O, E> {
        withCachePolicy(.reloadIgnoringLocalCacheData)
    }
}

public extension URLRequestConfiguration where O == Void {
    
    init<TE: Transformer>(route: URLConvertible,
         method: HTTPMethod = .get,
         headers: [String: String] = [:],
         cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
         timeout: TimeInterval = 60.0,
         expiration: ResourceExpiration = .never,
         error: TE)
        where TE.I == Data, TE.O == E {
        
        self.init(route: route,
                  method: method,
                  headers: headers,
                  cachePolicy: cachePolicy,
                  timeout: timeout,
                  expiration: expiration,
                  upstream: Upstream(with: EmptyTransformer(), using: ()),
                  downstream: EmptyTransformer(),
                  error: error)
    }
}

public extension URLRequestConfiguration where O == Void, E == Error {
    
    init(route: URLConvertible,
         method: HTTPMethod = .get,
         headers: [String: String] = [:],
         cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
         timeout: TimeInterval = 60.0,
         expiration: ResourceExpiration = .never) {
        
        self.init(route: route,
                  method: method,
                  headers: headers,
                  cachePolicy: cachePolicy,
                  timeout: timeout,
                  expiration: expiration,
                  upstream: Upstream(with: EmptyTransformer(), using: ()),
                  downstream: EmptyTransformer(),
                  error: EmptyTransformer())
    }
}
