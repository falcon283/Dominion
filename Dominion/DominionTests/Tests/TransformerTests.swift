//
//  TransformerTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest

import Dominion

class TransformerTests: XCTestCase {

    func testBlockTransformer() {
        let transformer = BlockTransformer<Double, Int> { Int($0) }
        
        XCTAssert((try? transformer.getTransformed(with: 0.0)) == 0, "Wrong Converted Value")
        XCTAssertThrowsError(try transformer.getTransformed(with: nil), "Expected Error") {
            XCTAssert(($0 as? TransformerFailure) == TransformerFailure.missingData, "Expected Missing Data")
        }
    }
    
    func testEmptyTransformer() {
        let transformer = EmptyTransformer<Double, Int>()
        
        XCTAssertThrowsError(try transformer.getTransformed(with: 0.0), "Expected Error") {
            XCTAssert(($0 as? TransformerFailure) == TransformerFailure.desiredEmpty, "Expected Desired Empty")
        }
        XCTAssertThrowsError(try transformer.getTransformed(with: nil), "Expected Error") {
            XCTAssert(($0 as? TransformerFailure) == TransformerFailure.desiredEmpty, "Expected Desired Empty")
        }
    }
    
    func testDecodableTransformer() {
        let transformer = DecodableTransformer<Int>()
        
        let data = try! JSONEncoder().encode(0)
        
        XCTAssert((try? transformer.getTransformed(with: data)) == 0, "Wrong Converted Value")
        XCTAssertThrowsError(try transformer.getTransformed(with: nil), "Expected Error") {
            XCTAssert(($0 as? TransformerFailure) == TransformerFailure.missingData, "Expected Missing Data")
        }
    }
    
    func testEncodableTransformer() {
        let transformer = EncodableTransformer<Int>()
        
        let data = try! JSONEncoder().encode(0)

        XCTAssert((try? transformer.getTransformed(with: 0)) == data, "Wrong Converted Value")
        XCTAssertThrowsError(try transformer.getTransformed(with: nil), "Expected Error") {
            XCTAssert(($0 as? TransformerFailure) == TransformerFailure.missingData, "Expected Missing Data")
        }
    }
}
