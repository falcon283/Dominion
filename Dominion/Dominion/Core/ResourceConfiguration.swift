//
//  ResourceConfiguration.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// Resource expiration Policy
public enum ResourceExpiration {
    
    /// The resource never expires.
    case never
    
    /// The resource expires after the given interval
    case interval(TimeInterval)
    
    /// The resource expires at the given date.
    case date(Date)
}

/// A ResourceConfiguration wraps the parameters identify the behaviour of the resourse. It also defines the mappings for the entity and the error returned from the request.
public protocol ResourceConfiguration {
    
    /// The request associated with the Configuration
    associatedtype Request
    
    /// The entity requested as output of the
    associatedtype Downstream
    
    /// The cache identifier if caching is required.
    var cacheIdentifier: String? { get }
    
    /// The expiration behaviour of the resource.
    var expiration: ResourceExpiration { get }
    
    /// A configuration copy that execute disregard the cache behaviour..
    func aggressiveConfiguration() -> Self
    
    /// The request to execute and pass to the ResourceProvider.
    func request() throws -> Request
    
    /// The transformer function to convert the given input to the requested output.
    /// - Parameter result: The input for the transform
    /// - Returns: The requested transformed object.
    func transform(_ result: Data?) throws -> Downstream
    
    /// The transformer function to convert the given input to the requested error.
    /// - Parameter result: The input for the transform
    /// - Returns: The requested transformed error.
    func transformError(_ result: Data?) throws -> Error
}
