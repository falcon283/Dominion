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

open class HTTPDataProvider: ResourceProvider {
    
    public typealias Request = URLRequest

    public var commonHeaders: [String: String] = [:]
    
    private let transport: HTTPTransport
    
    init(with transport: HTTPTransport) {
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
