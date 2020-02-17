//
//  ResourceProvider.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// A Resource provider is an object that perform a task and retrieve the resource entity asynchronously.
public protocol ResourceProvider {
    
    /// The associated Request able to handle the ResourceProvider.
    associatedtype Request
    
    /// Perform the task in order to retrieve the Resource entity asynchronously.
    /// - Parameters:
    ///   - configuration: The configuration to use to retrieve the Resource Entity.
    ///   - result: The action to run when a result for the task execution is available.
    /// - Returns: A `ResourceTask` to control the execution of the network request.
    func perform<C>(using configuration: C, result: @escaping (Result<Response<C.Downstream>, Error>) -> Void) throws -> ResourceTask
        where C: ResourceConfiguration, C.Request == Request
}
