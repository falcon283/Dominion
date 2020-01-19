//
//  HTTPDataProvider.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

enum URLSessionProviderError: Error {
    case unknown
    case invalidResponse
}

open class HTTPDataProvider: ResourceProvider {
    
    public typealias Request = URLRequest
    private let transport: HTTPTransport

    public var commonHeaders: [String: String] = [:]
    
    public init(with transport: HTTPTransport) {
        self.transport = transport
    }
    
    public func perform<C>(using configuration: C,
                           result: @escaping (Result<Response<C.Downstream>, Error>) -> Void) -> ResourceTask
        where C : ResourceConfiguration, Request == C.Request {
            
            var request = configuration.request
            request.allHTTPHeaderFields = commonHeaders + (request.allHTTPHeaderFields ?? [:])
            return transport.task(with: request) { (data, response, error) in
                
                if let response = response as? HTTPURLResponse {

                    if (200..<300) ~= response.statusCode {
                        if let data = data {
                            do {
                                let object = try configuration.transform(data)
                                result(.success(.value(object)))
                            } catch URLRequestConfigurationError.unknownDownstreamTransformer {
                                result(.success(.empty))
                            } catch {
                                result(.failure(error))
                            }
                        } else {
                            result(.success(.empty))
                        }
                    } else if let data = data {
                        do {
                            let object = try configuration.transformError(data)
                            result(.success(.error(object)))
                        } catch {
                            result(.failure(error))
                        }
                    } else if let error = error {
                        result(.failure(error))
                    } else {
                        result(.failure(URLSessionProviderError.unknown))
                    }
                } else {
                    result(.failure(URLSessionProviderError.invalidResponse))
                }
            }
    }
}
