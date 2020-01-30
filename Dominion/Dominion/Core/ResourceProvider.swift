//
//  ResourceProvider.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public protocol ResourceProvider {
    associatedtype Request
    
    func perform<C>(using configuration: C, result: @escaping (Result<Response<C.Downstream>, Error>) -> Void) throws -> ResourceTask
        where C: ResourceConfiguration, C.Request == Request
}
