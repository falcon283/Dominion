//
//  Transformer.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public enum TransformerFailure: Error {
    case desiredEmpty
    case missingData
}

public protocol Transformer {
    associatedtype I
    associatedtype O
    
    func getTransformed(with input: I?) throws -> O
}
