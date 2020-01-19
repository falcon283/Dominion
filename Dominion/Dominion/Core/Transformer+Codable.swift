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
    private let input: I
    
    public init(input: I, encoder: JSONEncoder = JSONEncoder()) {
        self.input = input
        self.encoder = encoder
    }
    
    public func getTransformed() throws -> O {
        try encoder.encode(input)
    }
}

public struct DecodableTransformer<O: Decodable>: Transformer {
    
    public typealias I = Data
    
    private let decoder: JSONDecoder
    private let input: I
    
    public init(input: I, decoder: JSONDecoder = JSONDecoder()) {
        self.input = input
        self.decoder = decoder
    }
    
    public func getTransformed() throws -> O {
        try decoder.decode(O.self, from: input)
    }
}
