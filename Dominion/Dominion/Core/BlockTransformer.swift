//
//  BlockTransformer.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public struct BlockTransformer<I, O>: Transformer {
        
    private let transform: (I) throws -> O
    
    public init(tranform closure: @escaping (I) throws -> O) {
        self.transform = closure
    }
    
    public func getTransformed(with input: I?) throws -> O {
        guard let input = input else { throw TransformerFailure.missingData }
        return try transform(input)
    }
}
