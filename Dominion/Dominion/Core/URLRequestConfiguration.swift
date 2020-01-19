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

public enum URLRequestConfigurationError: Error {
    case unknownErrorTransformer
    case unknownDownstreamTransformer
}

public struct URLRequestConfiguration<E>: ResourceConfiguration {
    
    public typealias Request = URLRequest
    public typealias Downstream = E

    public let expiration: ResourceExpiration
    
    private let backingRequest: () -> Request
    
    private let downstream: ((Data) throws -> E)?
    private let error: ((Data) throws -> Error)?

    public init(with request: @escaping () -> Request,
         expiration: ResourceExpiration = .never,
         downstream: ((Data) throws -> E)? = nil,
         error: ((Data) throws -> Error)? = nil) {
        
        self.backingRequest = request
        self.expiration = expiration
        self.downstream = downstream
        self.error = error
    }

    public init(route: URLConvertible,
         method: HTTPMethod = .get,
         headers: [String: String] = [:],
         cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
         timeout: TimeInterval = 60.0,
         expiration: ResourceExpiration = .never,
         upstream: (() -> Data?)? = nil,
         downstream: ((Data) throws -> E)? = nil,
         error: ((Data) throws -> Error)? = nil) {
        
        let builder: () -> Request = {
            var request = URLRequest(url: route.asUrl, cachePolicy: cachePolicy, timeoutInterval: timeout)
            request.httpMethod = method.rawValue
            request.allHTTPHeaderFields = headers
            if method != .get {
                request.httpBody = upstream?()
            }
            return request
        }
        
        self.init(with: builder, expiration: expiration, downstream: downstream, error: error)
    }
    
    public var request: Request {
        return backingRequest()
    }
    
    public func transform(_ result: Data) throws -> E {
        if let downstream = downstream {
            return try downstream(result)
        } else {
            throw URLRequestConfigurationError.unknownDownstreamTransformer
        }
    }

    public func transformError(_ result: Data) throws -> Error {
        if let error = error {
            return try error(result)
        } else {
            throw URLRequestConfigurationError.unknownErrorTransformer
        }
    }
    
    public func withCachePolicy(_ policy: URLRequest.CachePolicy) -> Self {
        Self.init(with: {
            var request = self.backingRequest()
            request.cachePolicy = policy
            return request
        })
    }
    
    public func aggressiveConfiguration() -> URLRequestConfiguration<E> {
        withCachePolicy(.reloadIgnoringLocalAndRemoteCacheData)
    }
}
