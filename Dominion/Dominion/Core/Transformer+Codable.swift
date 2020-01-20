//
//  Transformer+Codable.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public struct EncodableTransformer<I: Encodable>: Transformer {
    
    public typealias O = Data
    
    private let encoder: JSONEncoder
    
    public init(encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
    }
    
    public func getTransformed(with input: I?) throws -> O {
        guard let input = input else { throw TransformerFailure.missingData }
        return try encoder.encode(input)
    }
}

public struct DecodableTransformer<O: Decodable>: Transformer {
    
    public typealias I = Data
    
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    public func getTransformed(with input: I?) throws -> O {
        guard let input = input else { throw TransformerFailure.missingData }
        return try decoder.decode(O.self, from: input)
    }
}
