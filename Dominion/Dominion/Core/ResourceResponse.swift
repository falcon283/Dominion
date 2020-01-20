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
