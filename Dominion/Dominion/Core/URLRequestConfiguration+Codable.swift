//
//  URLRequestConfiguration+Codable.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public extension URLRequestConfiguration where O: Decodable, E == Error {
    
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
                  downstream: DecodableTransformer(),
                  error: EmptyTransformer())
    }
    
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
                      error: EmptyTransformer())
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
                  error: EmptyTransformer())
    }
}

public extension URLRequestConfiguration where O: Decodable, E: Decodable {
    
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
                  downstream: DecodableTransformer(),
                  error: DecodableTransformer())
    }
    
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
