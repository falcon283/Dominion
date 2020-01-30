//
//  RetryTimeFunctionTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 23/02/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
@testable import Dominion

class RetryTimeFunctionTests: XCTestCase {

    func testConstant() {
        let value = RetryTimeFunction.constant(1)
        
        XCTAssert(value.timeFunction(0) == 1, "Constant 1 is expected")
        XCTAssert(value.timeFunction(1) == 1, "Constant 1 is expected")
        XCTAssert(value.timeFunction(2) == 1, "Constant 1 is expected")
        XCTAssert(value.timeFunction(3) == 1, "Constant 1 is expected")
        XCTAssert(value.timeFunction(4) == 1, "Constant 1 is expected")
    }
    
    func testLinear() {
        let value = RetryTimeFunction.linear(1)
        
        XCTAssert(value.timeFunction(0) == 0, "Constant 0 is expected")
        XCTAssert(value.timeFunction(1) == 1, "Constant 1 is expected")
        XCTAssert(value.timeFunction(2) == 2, "Constant 2 is expected")
        XCTAssert(value.timeFunction(3) == 3, "Constant 3 is expected")
        XCTAssert(value.timeFunction(4) == 4, "Constant 4 is expected")
    }
    
    func testQuadratic() {
        let value = RetryTimeFunction.quadratic(1)
        
        XCTAssert(value.timeFunction(0) == 0, "Constant 0 is expected")
        XCTAssert(value.timeFunction(1) == 1, "Constant 1 is expected")
        XCTAssert(value.timeFunction(2) == 4, "Constant 4 is expected")
        XCTAssert(value.timeFunction(3) == 9, "Constant 9 is expected")
        XCTAssert(value.timeFunction(4) == 16, "Constant 16 is expected")
    }

    func testCubic() {
        let value = RetryTimeFunction.cubic(1)
        
        XCTAssert(value.timeFunction(0) == 0, "Constant 0 is expected")
        XCTAssert(value.timeFunction(1) == 1, "Constant 1 is expected")
        XCTAssert(value.timeFunction(2) == 8, "Constant 8 is expected")
        XCTAssert(value.timeFunction(3) == 27, "Constant 27 is expected")
        XCTAssert(value.timeFunction(4) == 64, "Constant 64 is expected")
    }

    func testExponential() {
        let value = RetryTimeFunction.exponential(1)
        
        XCTAssert(value.timeFunction(0) == 1, "Constant 0 is expected")
        XCTAssert(value.timeFunction(1) == 2, "Constant 1 is expected")
        XCTAssert(value.timeFunction(2) == 4, "Constant 4 is expected")
        XCTAssert(value.timeFunction(3) == 8, "Constant 8 is expected")
        XCTAssert(value.timeFunction(4) == 16, "Constant 16 is expected")
    }

    func testFibonacci() {
        let value = RetryTimeFunction.fibonacci(1)
        
        XCTAssert(value.timeFunction(0) == 0, "Constant 0 is expected")
        XCTAssert(value.timeFunction(1) == 1, "Constant 1 is expected")
        XCTAssert(value.timeFunction(2) == 1, "Constant 1 is expected")
        XCTAssert(value.timeFunction(3) == 2, "Constant 2 is expected")
        XCTAssert(value.timeFunction(4) == 3, "Constant 3 is expected")
    }
}
