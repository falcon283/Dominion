//
//  EmptyTransformer.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public struct EmptyTransformer<I, O>: Transformer {
    
    public func getTransformed(with input: I?) throws -> O {
        throw TransformerFailure.desiredEmpty
    }
}
