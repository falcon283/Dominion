//
//  FakeTransportResourceTaskTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
import Dominion

class FakeTransportResourceTaskTests: XCTestCase {

    func testSuspend() {

        let e = expectation(description: "Suspend")
        
        let task = FakeTransportResourceTask(on: .main, latency: .milliseconds(50), variance: .milliseconds(0)) {
            e.fulfill()
        }
        task.resume()
        task.suspend()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            task.resume()
        }
        
        wait(for: [e], timeout: 1)
    }
    
    func testCancel() {

        let e = expectation(description: "Cancel")
        e.isInverted = true
        
        let task = FakeTransportResourceTask(on: .main, latency: .milliseconds(50), variance: .milliseconds(0)) {
            e.fulfill()
        }
        task.resume()
        task.cancel()
        
        wait(for: [e], timeout: 1)
    }
    
    func testResume() {
        
        let e = expectation(description: "Resume")
        
        let task = FakeTransportResourceTask(on: .main, latency: .milliseconds(50), variance: .milliseconds(0)) {
            e.fulfill()
        }
        task.resume()
        
        wait(for: [e], timeout: 1)
    }
}
