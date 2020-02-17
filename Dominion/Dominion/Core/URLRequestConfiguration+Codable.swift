//
//  URLRequestConfiguration+Codable.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public extension URLRequestConfiguration where O: Decodable, E == Error {
    
    /// Convenience Initializer to create a configuration based on the given decodable transformer.
    /// - Parameters:
    ///   - route: The route of the resource.
    ///   - method: The method for the resource. Default get.
    ///   - headers: the headers of the resource. Default empty.
    ///   - cachePolicy: The cache policy of the resource. Default `.returnCacheDataElseLoad`
    ///   - timeout: The timeout to use while creating the network request. Default 60 seconds.
    ///   - expiration: The expiration behaviour. Default `.never`
    ///   - downstream: The downstream transformer. Default uses a standard JSONDecoder
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
    
    /// Convenience Initializer to create a configuration based on the given decodable transformers.
    /// - Parameters:
    ///   - route: The route of the resource.
    ///   - method: The method for the resource. Default get.
    ///   - headers: the headers of the resource. Default empty.
    ///   - cachePolicy: The cache policy of the resource. Default `.returnCacheDataElseLoad`
    ///   - timeout: The timeout to use while creating the network request. Default 60 seconds.
    ///   - expiration: The expiration behaviour. Default `.never`
    ///   - upstream: The upstream transformer.
    ///   - downstream: The downstream transformer. Default uses a standard JSONDecoder.
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
    
    /// Convenience Initializer to create a configuration based on the given transformers.
    /// - Parameters:
    ///   - route: The route of the resource.
    ///   - method: The method for the resource. Default get.
    ///   - headers: the headers of the resource. Default empty.
    ///   - cachePolicy: The cache policy of the resource. Default `.returnCacheDataElseLoad`
    ///   - timeout: The timeout to use while creating the network request. Default 60 seconds.
    ///   - expiration: The expiration behaviour. Default `.never`
    ///   - body: The body object to encode within the request.
    ///   - encoder: The encoder to use for the serialization. Defualt use a standard JSONEncoder.
    ///   - downstream: The downstream transformer. Default uses a standard JSONDecoder.
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
    
    /// Convenience Initializer to create a configuration based on the given transformers.
    /// - Parameters:
    ///   - route: The route of the resource.
    ///   - method: The method for the resource. Default get.
    ///   - headers: the headers of the resource. Default empty.
    ///   - cachePolicy: The cache policy of the resource. Default `.returnCacheDataElseLoad`
    ///   - timeout: The timeout to use while creating the network request. Default 60 seconds.
    ///   - expiration: The expiration behaviour. Default `.never`
    ///   - downstream: The downstream transformer. Default uses a standard JSONDecoder.
    ///   - error: The error transformer. Default uses a standard JSONDecoder.
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
    
    /// Convenience Initializer to create a configuration based on the given transformers.
    /// - Parameters:
    ///   - route: The route of the resource.
    ///   - method: The method for the resource. Default get.
    ///   - headers: the headers of the resource. Default empty.
    ///   - cachePolicy: The cache policy of the resource. Default `.returnCacheDataElseLoad`
    ///   - timeout: The timeout to use while creating the network request. Default 60 seconds.
    ///   - expiration: The expiration behaviour. Default `.never`
    ///   - upstream: The upstream transformer.
    ///   - downstream: The downstream transformer. Default uses a standard JSONDecoder.
    ///   - error: The error transformer. Default uses a standard JSONDecoder.
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
    
    /// Convenience Initializer to create a configuration based on the given transformers.
    /// - Parameters:
    ///   - route: The route of the resource.
    ///   - method: The method for the resource. Default get.
    ///   - headers: the headers of the resource. Default empty.
    ///   - cachePolicy: The cache policy of the resource. Default `.returnCacheDataElseLoad`
    ///   - timeout: The timeout to use while creating the network request. Default 60 seconds.
    ///   - expiration: The expiration behaviour. Default `.never`
    ///   - body: The body object to encode within the request.
    ///   - encoder: The encoder to use for the serialization. Defualt use a standard JSONEncoder.
    ///   - downstream: The downstream transformer. Default uses a standard JSONDecoder.
    ///   - error: The error transformer. Default uses a standard JSONDecoder.
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
