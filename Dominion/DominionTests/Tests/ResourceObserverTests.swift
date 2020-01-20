//
//  ResourceObserverTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
@testable import Dominion

class ResourceObserverTests: XCTestCase {

    var tokens: [CancellationToken] = []
    
    func testDeinitToken() {
        
        let e = expectation(description: "Deinit Token")
        
        DeinitCancellationToken {
            e.fulfill()
        }.store(in: &tokens)
        
        tokens.removeAll()
        
        wait(for: [e], timeout: 1)
    }

    func testResourceObserver() {
 
        let e = expectation(description: "Resource Observer")

        let observer = ResourceObserver<Int> { result in
            switch result {
            case .success(let value):
                XCTAssert(value == 5, "Wrong Expected Value")
            case .failure:
                XCTAssert(false, "A result success is expected")
            }
            e.fulfill()
        }
        
        observer.emit(.success(5))
        
        wait(for: [e], timeout: 1)
    }
}
