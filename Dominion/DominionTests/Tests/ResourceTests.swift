//
//  ResourceTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
@testable import Dominion

class ResourceTests: XCTestCase {

    let transport = FakeHTTPTransport(latency: .milliseconds(70), latencyVariance: .milliseconds(10))
    lazy var provider: HTTPDataProvider = { HTTPDataProvider(with: transport) }()
    
    var tokens: [CancellationToken] = []
    
    override func setUp() {
        transport.latency = .milliseconds(70)
    }
    
    // 1. taskResult success: resultDate != nil
    
    func testValidResultDate() {
        
        let e = expectation(description: "Valid Result Date")
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
        
        resource
            .observe { _ in e.fulfill() }
            .store(in: &tokens)
        
        wait(for: [e], timeout: 1)
        
        XCTAssert(resource.isResourceExpired == false)
    }
    
    // 2. taskResult failure: resultDate == nil
    
    func testInvalidResultDate() {
        
        let e = expectation(description: "Invalid Result Date")
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 400)
        
        let resource = Resource(with: c, using: provider)
        
        resource
            .observe { _ in e.fulfill() }
            .store(in: &tokens)
        
        wait(for: [e], timeout: 1)
        
        XCTAssert(resource.isResourceExpired == true)
    }
    
    func testRemoveObserverPerform() {
        
        let e = expectation(description: "Remove Observer")
        e.isInverted = true
        
        transport.latency = .milliseconds(100)
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
        
        resource
            .observe { _ in e.fulfill() }
            .store(in: &tokens)
        
        XCTAssert(resource.isRunning == true, "Resource expected to load when first observed")
        
        tokens.removeAll()
        
        wait(for: [e], timeout: 1)
        
        XCTAssert(resource.isRunning == false, "Resource is expected to have running false after the response")
    }
    
    // 3. No Perform/Refresh isRunning == false
    // 8. addObserver when running: skip
    
    func testNoDuplicatedPerform() {
        
        let e = expectation(description: "No Duplicated Perform")
        
        transport.latency = .milliseconds(100)
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
        
        resource
            .observe { _ in e.fulfill() }
            .store(in: &tokens)
        
        XCTAssert(resource.isRunning == true, "Resource expected to load when first observed")
        
        resource
            .observe { _ in }
            .store(in: &tokens)
        
        resource.refresh()
        
        wait(for: [e], timeout: 1)
        
        XCTAssert(resource.isRunning == false, "Resource is expected to have running false after the response")
    }
    
    // 4. expiration .never, isExpired == false

    func testExpirationNever() {
        
        let e = expectation(description: "Expiration Timeout")
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .never)
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
        
        resource
            .observe { _ in
                
                XCTAssert(resource.isResourceExpired == false, "Resource expected not to be expired")

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                    e.fulfill()
                }
        }
            .store(in: &tokens)
        
        wait(for: [e], timeout: 1)
        
        XCTAssert(resource.isResourceExpired == false, "Resource expected not to be expired")
    }
    
    // 5. expiration .interval, expiration test
    
    func testExpirationInterval() {
        
        let e = expectation(description: "Expiration Timeout")
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(0.1))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
        
        resource
            .observe { _ in
                
                XCTAssert(resource.isResourceExpired == false, "Resource expected not to be expired")

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                    e.fulfill()
                }
        }
        .store(in: &tokens)
        
        wait(for: [e], timeout: 1)
        
        XCTAssert(resource.isResourceExpired == true, "Resource expected not to be expired")
    }
    
    // 6. expiration .date, expiration test
    
    func testExpirationDate() {
        
        let e = expectation(description: "Expiration Date")
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .date(Date(timeIntervalSinceNow: 0.1)))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
        
        resource
            .observe { _ in
                
                XCTAssert(resource.isResourceExpired == false, "Resource expected not to be expired")

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                    e.fulfill()
                }
        }
            .store(in: &tokens)
        
        wait(for: [e], timeout: 1)
        
        XCTAssert(resource.isResourceExpired == true, "Resource expected not to be expired")
    }
    
    // 7. refresh, get response
    
    func testRefreshGetResponse() {
        
        let observation = expectation(description: "Observation")
        let refresh = expectation(description: "Refresh")

        var e = observation
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(0.1))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
        
        resource
            .observe { _ in e.fulfill() }
            .store(in: &tokens)
        
        wait(for: [observation], timeout: 1)
        
        e = refresh
        resource.refresh()
        
        wait(for: [refresh], timeout: 1)
    }
    
    // 9. addObserver when not running with expired data: force load
    
    func testAddObserverWithExpiredData() {
        
        let initial = expectation(description: "Not Running and Expired")
        initial.assertForOverFulfill = false
        
        let expired = expectation(description: "Add Observer When Expired")
        
        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(0.1))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
        
        XCTAssert(resource.isRunning == false, "Should not be running")
        
        resource
            .observe { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                    initial.fulfill()
                }
        }
        .store(in: &tokens)
        
        XCTAssert(resource.isRunning == true, "Should be running")
        
        wait(for: [initial], timeout: 1)
        
        XCTAssert(resource.isRunning == false, "Should not be running")
        XCTAssert(resource.isResourceExpired == true, "Should be expired")
        
        switch resource.state {
        case .data(let response):
            switch response {
            case .emptyValue:
                break
            default:
                XCTAssert(false, "Response should be .emptyValue - \(response)")
            }
        default:
            XCTAssert(false, "State should be .initial - \(resource.state)")
        }
        
        resource
            .observe { _ in expired.fulfill() }
            .store(in: &tokens)
        
        wait(for: [expired], timeout: 1)
    }
    
    // 10. addObserver when not running, not expired and result available: emission
    
    func testAddObserverNotExpiredResultAvailable() {
        
        let e1 = expectation(description: "Not Running")
        let e2 = expectation(description: "Not Running Result Available")

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
        
        XCTAssert(resource.isRunning == false, "Should not be running")
        
        resource
            .observe { _ in e1.fulfill() }
            .store(in: &tokens)
        
        XCTAssert(resource.isRunning == true, "Should be running")
        
        wait(for: [e1], timeout: 1)
        
        
        XCTAssert(resource.isRunning == false, "Should not be running")

        resource
            .observe { _ in e2.fulfill() }
            .store(in: &tokens)
        
        XCTAssert(resource.isRunning == false, "Should not be running")

        wait(for: [e2], timeout: 1)
        
        XCTAssert(resource.isRunning == false, "Should not be running")
    }
    
    // 11. addObserver when not running, error: load
    
    func testAddObserverNoResultAvailable() {
        
        let initial = expectation(description: "Not Running")
        initial.assertForOverFulfill = false
        
        let error = expectation(description: "Not Running Error")

        let c = URLRequestConfiguration<User, ApiError>(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 400)
        
        let resource = Resource(with: c, using: provider)
        
        XCTAssert(resource.isRunning == false, "Should not be running")
        
        resource
            .observe { _ in initial.fulfill() }
            .store(in: &tokens)
        
        XCTAssert(resource.isRunning == true, "Should be running")
        
        wait(for: [initial], timeout: 1)
        
        XCTAssert(resource.isRunning == false, "Should not be running")
        
        switch resource.state {
        case .error:
            break
        default:
            XCTAssert(false, "State should be .initial - \(resource.state)")
        }
        
        resource
            .observe { _ in error.fulfill() }
            .store(in: &tokens)
        
        wait(for: [error], timeout: 1)
    }
    
    // 12. Initial State
    
    func testCheckInitialState() {
        
        let e = expectation(description: "Initial State")

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: userData, statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
        
        switch resource.state {
        case .initial:
            break
        default:
            XCTAssert(false, "State should be .initial - \(resource.state)")
        }
        
        XCTAssert(resource.isRunning == false, "Should not be running")

        resource
            .observe { _ in e.fulfill() }
            .store(in: &tokens)
        
        XCTAssert(resource.isRunning == true, "Should be running")

        wait(for: [e], timeout: 1)
        
        XCTAssert(resource.isRunning == false, "Should not be running")
    }
}
