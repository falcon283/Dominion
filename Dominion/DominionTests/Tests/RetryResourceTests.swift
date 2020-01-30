//
//  RetryResourceTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 23/02/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
@testable import Dominion

class RetryResourceTests: XCTestCase {

    let transport = FakeHTTPTransport(latency: .milliseconds(70), latencyVariance: .milliseconds(10))
    lazy var provider: HTTPDataProvider = { HTTPDataProvider(with: transport) }()
    
    var tokens: [CancellationToken] = []
    
    override func setUp() {
        transport.latency = .milliseconds(70)
    }
    
    // 1. Retry Success
    
    func testRetrySuccess() {
        
        let e = expectation(description: "Resource Observer")
        let r = expectation(description: "Retry")

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: Data(), statusCode: 401)
        
        let resource = Resource(with: c, using: provider)
            .retryOnError { [weak self] attempt, refresh in
                
                func enqueue() -> CancellationToken {
                    let item = DispatchWorkItem { refresh() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: item)
                    return DeinitCancellationToken { item.cancel() }
                }
                
                switch attempt {
                case 0, 1:
                    return enqueue()
                case 2:
                    r.fulfill()
                    self?.transport.inject(c, data: Data(), statusCode: 200)
                    return enqueue()
                default:
                    return nil
                }
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
    
    // 2. Retry Success With Multiple Observers
    
    func testRetrySuccessMultipleObservers() {
        
        let e1 = expectation(description: "Resource Observer 1")
        let e2 = expectation(description: "Resource Observer 2")
        let r = expectation(description: "Retry")

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: Data(), statusCode: 401)
        
        let resource = Resource(with: c, using: provider)
            .retryOnError { [weak self] attempt, refresh in
                    
                    func enqueue() -> CancellationToken {
                        let item = DispatchWorkItem { refresh() }
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: item)
                        return DeinitCancellationToken { item.cancel() }
                    }
                    
                    switch attempt {
                    case 0, 1:
                        return enqueue()
                    case 2:
                        r.fulfill()
                        self?.transport.inject(c, data: Data(), statusCode: 200)
                        return enqueue()
                    default:
                        return nil
                    }
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


    // 3. Success - Retry - Success
    
    func testSuccessRetrySuccess() {
        
        let e1 = expectation(description: "Resource Success 1")
        e1.assertForOverFulfill = false
        let e2 = expectation(description: "Resource Success 2")
        let r = expectation(description: "Retry")

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: Data(), statusCode: 200)
        
        let resource = Resource(with: c, using: provider)
            .retryOnError { [weak self] attempt, refresh in
                
                func enqueue() -> CancellationToken {
                    let item = DispatchWorkItem { refresh() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: item)
                    return DeinitCancellationToken { item.cancel() }
                }
                
                switch attempt {
                case 0, 1:
                    return enqueue()
                case 2:
                    r.fulfill()
                    self?.transport.inject(c, data: Data(), statusCode: 200)
                    return enqueue()
                default:
                    return nil
                }
        }
        
        resource.observe {
            switch $0.response {
            case .emptyValue:
                e1.fulfill()
            default:
                break
            }
        }.store(in: &tokens)
                
        wait(for: [e1], timeout: 1)
        
        transport.inject(c, data: Data(), statusCode: 401)
        resource.refresh()

        resource.observe {
            switch $0.response {
            case .emptyValue:
                e2.fulfill()
            default:
                break
            }
        }.store(in: &tokens)
        
        wait(for: [e2, r], timeout: 1)

        XCTAssert(resource.isResourceExpired == false)
    }
    
    // 5. No Retry Needed

    func testNoRetryRequired() {
        
        let e = expectation(description: "Resource Observer")

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: Data(), statusCode: 401)
        
        let resource = Resource(with: c, using: provider)
            .retryOnError(3, in: .constant(0.1)) { _ in false }
        
        resource.observe {
            switch $0.response {
            case .emptyError:
                e.fulfill()
            default:
                break
            }
        }
        .store(in: &tokens)
                
        wait(for: [e], timeout: 1)
    }

    // 6. Retry Error
    
    func testRetryError() {
        
        let e = expectation(description: "Resource Observer")

        let c = URLRequestConfiguration(route: Routes.user, expiration: .interval(60))
        
        transport.inject(c, data: Data(), statusCode: 401)
        
        let resource = Resource(with: c, using: provider)
            .retryOnError(3, in: .constant(0.1)) { _ in false }
        
        resource.observe {
            switch $0.response {
            case .emptyError:
                e.fulfill()
            default:
                break
            }
        }
        .store(in: &tokens)
                
        wait(for: [e], timeout: 1)
    }
}
