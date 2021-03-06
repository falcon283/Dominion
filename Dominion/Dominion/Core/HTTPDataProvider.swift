//
//  HTTPDataProvider.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

enum HTTPDataProviderError: Error {
    case unknown
    case invalidResponse
}

/// A provider suitable for non local request. Request is of `URLRequest` type and a network request is performed in order to retrieve the resource.
open class HTTPDataProvider: ResourceProvider {
    
    public typealias Request = URLRequest
    
    /// The headers to use for all the network requests.
    public var commonHeaders: [String: String] = [:]
    
    private let transport: HTTPTransport
    
    /// Designated initializer.
    /// - Parameter transport: The transport used to execute the raw request.
    public init(with transport: HTTPTransport) {
        self.transport = transport
    }
    
    public func perform<C>(using configuration: C,
                           result: @escaping (Result<Response<C.Downstream>, Error>) -> Void) throws -> ResourceTask
        where C : ResourceConfiguration, Request == C.Request {
            
            let result = Thread.isMainThread ? result : { r in DispatchQueue.main.async { result(r) }}
            
            var request = try configuration.request()
            request.allHTTPHeaderFields = commonHeaders + (request.allHTTPHeaderFields ?? [:])
            return transport.task(with: request) { (data, response, error) in
                
                if let response = response as? HTTPURLResponse {
                    
                    if (200..<300) ~= response.statusCode {
                        do {
                            let object = try configuration.transform(data)
                            result(.success(.value(object)))
                        } catch TransformerFailure.desiredEmpty {
                            result(.success(.emptyValue))
                        } catch {
                            result(.failure(error))
                        }
                    } else if let error = error {
                        do {
                            let object = try configuration.transformError(data)
                            result(.success(.error(object)))
                        } catch TransformerFailure.desiredEmpty {
                            result(.success(.emptyError(error)))
                        } catch {
                            result(.failure(error))
                        }
                    } else {
                        result(.failure(HTTPDataProviderError.unknown))
                    }
                } else {
                    result(.failure(HTTPDataProviderError.invalidResponse))
                }
            }
    }
}
