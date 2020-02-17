//
//  ResourceServiceTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 25/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
import Dominion

class ResourceServiceTests: XCTestCase {
    
    let provider = HTTPDataProvider(with: FakeHTTPTransport(latency: .milliseconds(70), latencyVariance: .milliseconds(10)))
    lazy var service = ResourceService(provider: provider)
    
    func testResourceCachingRetrieval() {
        
        let c1 = URLRequestConfiguration(route: Routes.user)
        let c2 = URLRequestConfiguration(route: Routes.user)

        let resource1 = service[resource: c1]
        let resource2 = service[resource: c2]
        
        XCTAssert(resource1 === resource2, "Resource should be cached")
    }
    
}
