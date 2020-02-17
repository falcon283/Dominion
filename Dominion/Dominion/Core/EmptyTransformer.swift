//
//  EmptyTransformer.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// A simple transformer that map any input thorwing a `TransformerFailure.desiredEmpty` exception for gracefull handling.
public struct EmptyTransformer<I, O>: Transformer {
    
    /// Designated initializer
    public init() { }
    
    public func getTransformed(with input: I?) throws -> O {
        throw TransformerFailure.desiredEmpty
    }
}
