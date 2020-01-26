//
//  ResourceResponse.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public enum Response<T> {
    case value(T)
    case emptyValue
    case error(Error)
    case emptyError(Error)
}

public extension Response {
    
    var value: T? {
        switch self {
        case .value(let value):
            return value
        case .emptyValue, .emptyError, .error:
            return nil
        }
    }
    
    var error: Error? {
        switch self {
        case .error(let error):
            return error
        case .value, .emptyValue, .emptyError:
            return nil
        }
    }
}
