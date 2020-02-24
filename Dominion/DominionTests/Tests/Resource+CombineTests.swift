//
//  Resource+CombineTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 24/02/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
import Combine
import Dominion

@available(iOS 13.0, *)
class Resource_CombineTests: XCTestCase {
    
    let transport = FakeHTTPTransport(latency: .milliseconds(70), latencyVariance: .milliseconds(10))
    lazy var provider: HTTPDataProvider = { HTTPDataProvider(with: transport) }()
    
    private var bag: [AnyCancellable] = []
    
    override func setUp() {
        transport.latency = .milliseconds(70)
    }
    
    // 1. Publisher
    
    func testPublisher() {
        
        let e = expectation(description: "Publisher")
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        Resource(with: c, using: provider).publisher()
            .sink { _ in
                e.fulfill()
        }.store(in: &bag)
        
        wait(for: [e], timeout: 1)
    }
    
    // 2. Publisher Refresh
    
    func testPublisherRefresh() {
        
        let e = expectation(description: "Publisher")
        e.assertForOverFulfill = false
        
        let r = expectation(description: "Refresh")
        r.expectedFulfillmentCount = 2
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let refresh = PassthroughSubject<Void, Never>()
        
        Resource(with: c, using: provider).publisher(using: refresh.eraseToAnyPublisher())
            .sink { _ in
                e.fulfill()
                r.fulfill()
        }.store(in: &bag)
        
        wait(for: [e], timeout: 1)
        
        refresh.send()
        
        wait(for: [r], timeout: 1)
    }
    
    // 3. ObservableResource
    
    func testObservableObject() {
        
        let e = expectation(description: "ObservableResource")
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let object = Resource(with: c, using: provider).observableObject()
        
        object.objectWillChange.sink { _ in
            e.fulfill()
        }.store(in: &bag)
        
        wait(for: [e], timeout: 1000)
    }
    
    // 4. ObservableResource Refresh
    
    func testObservableObjectRefresh() {
        
        let e = expectation(description: "ObservableResource")
        e.assertForOverFulfill = false
        
        let r = expectation(description: "Refresh")
        r.expectedFulfillmentCount = 2
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let refresh = PassthroughSubject<Void, Never>()
        
        let object = Resource(with: c, using: provider).observableObject(using: refresh.eraseToAnyPublisher())
        
        object.objectWillChange.sink { _ in
            e.fulfill()
            r.fulfill()
        }.store(in: &bag)
        
        wait(for: [e], timeout: 1)
        
        refresh.send()
        
        wait(for: [r], timeout: 1)
    }
}
