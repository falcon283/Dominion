//
//  ResourceConfiguration.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public enum ResourceExpiration {
    case never
    case interval(TimeInterval)
    case date(Date)
}

public protocol ResourceConfiguration {
    associatedtype Request
    associatedtype Downstream
    
    var cacheIdentifier: String? { get }
    var expiration: ResourceExpiration { get }
    func aggressiveConfiguration() -> Self
    
    func request() throws -> Request
    
    func transform(_ result: Data?) throws -> Downstream
    func transformError(_ result: Data?) throws -> Error
}
