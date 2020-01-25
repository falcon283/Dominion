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
         expiration: ResourceExpiration = .never,
         downstream: DecodableTransformer<O> = .init()) {
        
        self.init(route: route,
                  method: method,
                  headers: headers,
                  cachePolicy: cachePolicy,
                  timeout: timeout,
                  expiration: expiration,
                  upstream: Upstream(with: EmptyTransformer(), using: ()),
                  downstream: downstream,
                  error: EmptyTransformer())
    }
    
    init<TU: Transformer>(
        route: URLConvertible,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeout: TimeInterval = 60.0,
        expiration: ResourceExpiration = .never,
        upstream: Upstream<TU, TU.I>,
        downstream: DecodableTransformer<O> = .init())
        where TU.O == Data {
            
            self.init(route: route,
                      method: method,
                      headers: headers,
                      cachePolicy: cachePolicy,
                      timeout: timeout,
                      expiration: expiration,
                      upstream: upstream,
                      downstream: downstream,
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
        encoder: JSONEncoder = JSONEncoder(),
        downstream: DecodableTransformer<O> = .init()) {
        
        self.init(route: route,
                  method: method,
                  headers: headers,
                  cachePolicy: cachePolicy,
                  timeout: timeout,
                  expiration: expiration,
                  upstream: Upstream(with: EncodableTransformer(encoder: encoder), using: body),
                  downstream: downstream,
                  error: EmptyTransformer())
    }
}

public extension URLRequestConfiguration where O: Decodable, E: Decodable {
    
    init(route: URLConvertible,
         method: HTTPMethod = .get,
         headers: [String: String] = [:],
         cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
         timeout: TimeInterval = 60.0,
         expiration: ResourceExpiration = .never,
         downstream: DecodableTransformer<O> = .init(),
         error: DecodableTransformer<E> = .init()) {
        
        self.init(route: route,
                  method: method,
                  headers: headers,
                  cachePolicy: cachePolicy,
                  timeout: timeout,
                  expiration: expiration,
                  upstream: Upstream(with: EmptyTransformer(), using: ()),
                  downstream: downstream,
                  error: error)
    }
    
    init<TU: Transformer>(
        route: URLConvertible,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeout: TimeInterval = 60.0,
        expiration: ResourceExpiration = .never,
        upstream: Upstream<TU, TU.I>,
        downstream: DecodableTransformer<O> = .init(),
        error: DecodableTransformer<E> = .init())
        where TU.O == Data {
            
            let identifier = "\(route.asUrl.absoluteString)-\(method.rawValue)"
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
    
    init<I: Encodable>(
        route: URLConvertible,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        timeout: TimeInterval = 60.0,
        expiration: ResourceExpiration = .never,
        body: I,
        encoder: JSONEncoder = JSONEncoder(),
        downstream: DecodableTransformer<O> = .init(),
        error: DecodableTransformer<E> = .init()) {
        
        self.init(route: route,
                  method: method,
                  headers: headers,
                  cachePolicy: cachePolicy,
                  timeout: timeout,
                  expiration: expiration,
                  upstream: Upstream(with: EncodableTransformer(encoder: encoder), using: body),
                  downstream: downstream,
                  error: error)
    }
}
