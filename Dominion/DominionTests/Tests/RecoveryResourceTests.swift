//
//  RecoveryResourceTestes.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 23/02/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
@testable import Dominion

class RecoveryResourceTests: XCTestCase {

    let transport = FakeHTTPTransport(latency: .milliseconds(70), latencyVariance: .milliseconds(10))
    lazy var provider: HTTPDataProvider = { HTTPDataProvider(with: transport) }()
    
    var tokens: [CancellationToken] = []
    
    override func setUp() {
        transport.latency = .milliseconds(70)
    }

    // 1. Recovery Success Once
    
    func testRecoverySuccess() {
        
        let e = expectation(description: "Resource Observer")
        let r = expectation(description: "Recovery")

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        let a = URLRequestConfiguration(route: Routes.authorization, expiration: .interval(0))
        
        transport.inject(c, data: Data(), statusCode: 401)
        transport.inject(a, data: Data(), statusCode: 200)

        let resource = Resource(with: c, using: provider)
            .recover(using: Resource(with: a, using: provider)) { [weak self] _ in
                self?.transport.inject(c, data: userData, statusCode: 200)
                r.fulfill()
        }
        
        resource.observe {
            switch $0.response {
            case .emptyValue:
                e.fulfill()
            default:
                break
            }
        }
        .store(in: &tokens)
                
        wait(for: [e, r], timeout: 1)
        
        XCTAssert(resource.isResourceExpired == false)
    }
    
    // 2. Recovery Success With Multiple Observers

    func testRecoverySuccessMultipleObservers() {
        
        let e1 = expectation(description: "Resource Observer 1")
        let e2 = expectation(description: "Resource Observer 2")
        let r = expectation(description: "Recovery")

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        let a = URLRequestConfiguration(route: Routes.authorization, expiration: .interval(0))
        
        transport.inject(c, data: Data(), statusCode: 401)
        transport.inject(a, data: Data(), statusCode: 200)

        let resource = Resource(with: c, using: provider)
            .recover(using: Resource(with: a, using: provider)) { [weak self] _ in
                self?.transport.inject(c, data: userData, statusCode: 200)
                r.fulfill()
        }
        
        resource.observe {
            switch $0.response {
            case .emptyValue:
                e1.fulfill()
            default:
                break
            }
        }
        .store(in: &tokens)
        
        resource.observe {
            switch $0.response {
            case .emptyValue:
                e2.fulfill()
            default:
                break
            }
        }
        .store(in: &tokens)
        
        wait(for: [e1, e2, r], timeout: 1)
        
        XCTAssert(resource.isResourceExpired == false)
    }
    
    // 3. Success - Recovery - Success
    
    func testSuccessRecoverySuccess() {
        
        let e1 = expectation(description: "Resource First Success")
        let e2 = expectation(description: "Resource Success after Recovery")
        e2.expectedFulfillmentCount = 2
        let r = expectation(description: "Recovery")

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        let a = URLRequestConfiguration(route: Routes.authorization, expiration: .interval(0))
        
        transport.inject(c, data: userData, statusCode: 200)
        transport.inject(a, data: Data(), statusCode: 200)

        let resource = Resource(with: c, using: provider)
            .recover(using: Resource(with: a, using: provider)) { [weak self] _ in
                self?.transport.inject(c, data: userData, statusCode: 200)
                r.fulfill()
        }
        
        var initialSuccessReceived = false
        
        resource.observe { [weak self] in
            switch $0.response {
            case .emptyValue:
                guard initialSuccessReceived == false else { return }
                initialSuccessReceived = true
                self?.transport.inject(c, data: userData, statusCode: 401)
                e1.fulfill()
            default:
                break
            }
        }
        .store(in: &tokens)
        
        // Success Expected, No Recovery Needed.
        wait(for: [e1], timeout: 1)
        
        resource.observe {
            switch $0.response {
            case .emptyValue:
                e2.fulfill()
            default:
                break
            }
        }
        .store(in: &tokens)
        
        resource.refresh()
        
        // Fake Mock will now return error for the refresh and recovery is expected.
        wait(for: [e2, r], timeout: 1)
        
        XCTAssert(resource.isResourceExpired == false)
    }
    
    // 5. No Recovery Needed
    
    func testNoRecoveryRequired() {
        
        let e = expectation(description: "Resource Observer")
        let r = expectation(description: "Recovery")
        r.isInverted = true

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        let a = URLRequestConfiguration(route: Routes.authorization, expiration: .interval(0))
        
        transport.inject(c, data: Data(), statusCode: 401)
        transport.inject(a, data: Data(), statusCode: 200)

        let resource = Resource(with: c, using: provider)
            .recover(using: Resource(with: a, using: provider), shouldRecovery: { _ in false }) { [weak self] _ in
                self?.transport.inject(c, data: userData, statusCode: 200)
                r.fulfill()
        }
        
        resource.observe {
            switch $0.response {
            case .emptyError:
                e.fulfill()
            default:
                break
            }
        }
        .store(in: &tokens)
                
        wait(for: [e, r], timeout: 1)
    }
    
    // 6. Recovery Error
    func testRecoveryError() {
        
        let e = expectation(description: "Resource Observer")
        let r = expectation(description: "Recovery")
        r.isInverted = true

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        let a = URLRequestConfiguration(route: Routes.authorization, expiration: .interval(0))
        
        transport.inject(c, data: Data(), statusCode: 401)
        transport.inject(a, data: Data(), statusCode: 400)

        let resource = Resource(with: c, using: provider)
            .recover(using: Resource(with: a, using: provider)) { [weak self] _ in
                self?.transport.inject(c, data: userData, statusCode: 200)
                r.fulfill()
        }
        
        resource.observe {
            switch $0.response {
            case .emptyError:
                e.fulfill()
            default:
                break
            }
        }
        .store(in: &tokens)
                
        wait(for: [e, r], timeout: 1)
    }
}
