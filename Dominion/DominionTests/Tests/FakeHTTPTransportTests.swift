//
//  FakeHTTPTransportTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
@testable import Dominion

class FakeHTTPTransportTests: XCTestCase {
    
    let provider = FakeHTTPTransport(latency: .milliseconds(70), latencyVariance: .milliseconds(10))
    
    func testResponseFoundSuccess() {
        
        let e = expectation(description: "Response Success")
        
        let configuration = URLRequestConfiguration<User, ApiError>(route: Routes.user)
        
        provider.inject(configuration, data: userData, statusCode: 200)
        
        let task = try! provider.task(with: configuration.request()) { (data, response, error) in
            XCTAssert(data != nil, "Data should not be nil")
            XCTAssert(response != nil, "Response should not be nil")
            XCTAssert(error == nil, "Error should be nil")
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    func testResponseFoundError() {
        
        let e = expectation(description: "Response Error")
        
        let configuration = URLRequestConfiguration<User, ApiError>(route: Routes.user)
        
        provider.inject(configuration, data: apiErrorData, statusCode: 400)
        
        let task = try! provider.task(with: configuration.request()) { (data, response, error) in
            XCTAssert(data != nil, "Data should not be nil")
            XCTAssert(response != nil, "Response should not be nil")
            XCTAssert(error != nil, "Error should not be nil")
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    func testResponseNotFound() {
        let e = expectation(description: "Response Not Found")
        
        let configuration = URLRequestConfiguration<User, ApiError>(route: Routes.user)
        
        let task = try! provider.task(with: configuration.request()) { (data, response, error) in
            XCTAssert(data == nil, "Data should be nil")
            XCTAssert(response == nil, "Response should be nil")
            XCTAssert((error as? FakeHTTPTransportError) == .responseNotFound, "Response should be unknown")
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
    
    func testCleanUp() {
        let e = expectation(description: "Clenup")
        
        let configuration = URLRequestConfiguration<User, ApiError>(route: Routes.user)
        
        provider.inject(configuration, data: userData, statusCode: 200)
        
        provider.cleanup()
        
        let task = try! provider.task(with: configuration.request()) { (data, response, error) in
            XCTAssert(data == nil, "Data should be nil")
            XCTAssert(response == nil, "Response should be nil")
            XCTAssert((error as? FakeHTTPTransportError) == .responseNotFound, "Response should be unknown")
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
}
