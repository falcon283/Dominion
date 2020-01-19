//
//  URLConvertible.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public protocol URLConvertible {
    var asUrl: URL { get }
}

extension URL: URLConvertible {
    public var asUrl: URL {
        return self
    }
}
