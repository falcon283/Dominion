//
//  HTTPServiceTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 25/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
import Dominion

class HTTPServiceTests: XCTestCase {
    
    let provider = HTTPDataProvider(with: FakeHTTPTransport(latency: .milliseconds(70), latencyVariance: .milliseconds(10)))
    lazy var service = HTTPService(provider: provider)
    
    func testResourceCachingRetrieval() {
        
        let c1 = URLRequestConfiguration(route: Routes.user)
        let c2 = URLRequestConfiguration(route: Routes.user)

        let resource1 = service.getResource(for: c1)
        let resource2 = service.getResource(for: c2)
        
        XCTAssert(resource1 === resource2, "Resource should be cached")
    }
    
}
