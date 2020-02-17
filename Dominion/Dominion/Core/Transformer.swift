//
//  Transformer.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// Possible Error during object Mapping.
public enum TransformerFailure: Error {
    /// Received an object but the receiver asked to ignore the downstream. User for granceful error handling
    case desiredEmpty
    
    /// The downstream is empty and the requested object mapping is not possble to fullfill.
    case missingData
}

/// An object transformer. It's used to transform a given input to a particular output.
public protocol Transformer {
    associatedtype I
    associatedtype O
    
    func getTransformed(with input: I?) throws -> O
}
