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

/// A ResourceConfiguration object usefull for Network request based on URLRequest.
public struct URLRequestConfiguration<O, E: Error>: ResourceConfiguration {
    
    public typealias Request = URLRequest
    public typealias Downstream = O
    
    public let expiration: ResourceExpiration
    public let cacheIdentifier: String?
    
    private let backingRequest: () throws -> Request
    
    private let downstream: (Data?) throws -> O
    private let error: (Data?) throws -> E
    
    /// Designated initializer
    /// - Parameters:
    ///   - cacheIdentifier: The cache identifiier to use within the ResourceService.
    ///   - expiration: The expiration behaviour.
    ///   - downstream: The downstream transformer.
    ///   - error: The error transformer
    ///   - request: The request object builder.
    public init<TD: Transformer, TE: Transformer>(
        cacheIdentifier: String?,
        expiration: ResourceExpiration = .never,
        downstream: TD,
        error: TE,
        with request: @escaping () throws -> Request)
        where TD.I == Data, TD.O == O, TE.I == Data, TE.O == E {
            
            self.cacheIdentifier = cacheIdentifier
            self.backingRequest = request
            self.expiration = expiration
            self.downstream = downstream.getTransformed
            self.error = error.getTransformed
    }
    
    /// Convenience Initializer to create a configuration based on the given transformers.
    /// - Parameters:
    ///   - route: The route of the resource.
    ///   - method: The method for the resource. Default get.
    ///   - headers: the headers of the resource. Default empty.
    ///   - cachePolicy: The cache policy of the resource. Default `.returnCacheDataElseLoad`
    ///   - timeout: The timeout to use while creating the network request. Default 60 seconds.
    ///   - expiration: The expiration behaviour. Default `.never`
    ///   - upstream: The upstream transformer.
    ///   - downstream: The downstream transformer.
    ///   - error: The error transformer
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
            
            let id = Self.getResourceIdentifier(for: route.asUrl, method: method)
            
            self.init(cacheIdentifier: id, expiration: expiration, downstream: downstream, error: error) {
                guard let url = route.asUrl else { throw URLConvertibleError.invalidURL(route) }
                var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeout)
                request.httpMethod = method.rawValue
                request.allHTTPHeaderFields = headers
                if method != .get {
                    request.httpBody = try? upstream.transformer.getTransformed(with: upstream.input)
                }
                return request
            }
    }
    
    public func request() throws -> URLRequest {
        try backingRequest()
    }
        
    public func transform(_ result: Data?) throws -> O {
        try downstream(result)
    }
    
    public func transformError(_ result: Data?) throws -> Error {
        try error(result)
    }
    
    public func withCachePolicy(_ policy: URLRequest.CachePolicy) -> Self {
        Self.init(
            cacheIdentifier: cacheIdentifier,
            expiration: expiration,
            downstream: BlockTransformer(tranform: downstream),
            error: BlockTransformer(tranform: error)) {
                
                var request = try self.backingRequest()
                request.cachePolicy = policy
                return request
        }
    }
    
    public func aggressiveConfiguration() -> URLRequestConfiguration<O, E> {
        withCachePolicy(.reloadIgnoringLocalCacheData)
    }
}

extension URLRequestConfiguration {
    
    static func getResourceIdentifier(for url: URL?, method: HTTPMethod) -> String? {
        method == .get ? url.map { [method.rawValue, $0.absoluteString].joined(separator: "|") } : nil
    }
}

public extension URLRequestConfiguration where O == Void {
    
    /// Convenience Initializer to create a configuration based on the given transformer error ignoring the incoming downstream.
    /// - Parameters:
    ///   - route: The route of the resource.
    ///   - method: The method for the resource. Default get.
    ///   - headers: the headers of the resource. Default empty.
    ///   - cachePolicy: The cache policy of the resource. Default `.returnCacheDataElseLoad`
    ///   - timeout: The timeout to use while creating the network request. Default 60 seconds.
    ///   - expiration: The expiration behaviour. Default `.never`
    ///   - error: The error transformer
    init<TE: Transformer>(
        route: URLConvertible,
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
    
    /// Convenience Initializer to create a configuration ignoring downstream and custom error..
    /// - Parameters:
    ///   - route: The route of the resource.
    ///   - method: The method for the resource. Default get.
    ///   - headers: the headers of the resource. Default empty.
    ///   - cachePolicy: The cache policy of the resource. Default `.returnCacheDataElseLoad`
    ///   - timeout: The timeout to use while creating the network request. Default 60 seconds.
    ///   - expiration: The expiration behaviour. Default `.never`
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
