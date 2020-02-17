//
//  Transformer+Codable.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// An Encodable Transformer
public struct EncodableTransformer<I: Encodable>: Transformer {
    
    public typealias O = Data
    
    private let encoder: JSONEncoder
    
    /// Designated initializer
    /// - Parameter encoder: The encoder to use for the mapping.
    public init(encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
    }
    
    public func getTransformed(with input: I?) throws -> O {
        guard let input = input else { throw TransformerFailure.missingData }
        return try encoder.encode(input)
    }
}

/// A Decodable Transformer
public struct DecodableTransformer<O: Decodable>: Transformer {
    
    public typealias I = Data
    
    private let decoder: JSONDecoder
    
    /// Designated initializer
    /// - Parameter decoder: The decoder to use for the mapping.
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    public func getTransformed(with input: I?) throws -> O {
        guard let input = input else { throw TransformerFailure.missingData }
        return try decoder.decode(O.self, from: input)
    }
}
