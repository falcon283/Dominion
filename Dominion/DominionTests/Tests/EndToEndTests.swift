//
//  EndToEndTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 23/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
import Dominion

class EndToEndTests: XCTestCase {

    private var tokens: [CancellationToken] = []
    
    func testEndToEndMyJSON() {
        
        let e = expectation(description: "EndToEndExpectation")
        
        let c = URLRequestConfiguration<User, Error>(route: Routes.user)
        let resource = Resource(with: c, using: HTTPDataProvider(with: URLSession.shared))
        
        resource
            .observe { result in
                switch result {
                case .success(let response):
                    switch response {
                    case .value:
                        break
                    default:
                        XCTAssert(false, "Expected User")
                    }
                default:
                    XCTAssert(false, "Expected User")
                }
                e.fulfill()
        }.store(in: &tokens)
        
        wait(for: [e], timeout: 60)
    }
}
