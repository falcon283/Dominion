//
//  ResourceResponse.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// The response of the Resource retrieval.
public enum Response<T> {
    
    /// The response contains a value.
    case value(T)
    
    /// The response contains a value but the receiver is not interested in it.
    case emptyValue
    
    /// The response contains an incoming error.
    case error(Error)
    
    /// The response contains an incoming error but the receiver is not interested in it and a generic error will be forwarded.
    case emptyError(Error)
}

public extension Response {
    
    /// The value of the Response.
    var value: T? {
        switch self {
        case .value(let value):
            return value
        case .emptyValue, .emptyError, .error:
            return nil
        }
    }
    
    /// The custom error of the response.
    var error: Error? {
        switch self {
        case .error(let error):
            return error
        case .value, .emptyValue, .emptyError:
            return nil
        }
    }
}
