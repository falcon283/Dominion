//
//  ThreadSafeTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest
@testable import Dominion

class ThreadSafeTests: XCTestCase {

    var array: [Int] = []
    
    func testThreadSafe() {
        
        if #available(iOS 10.0, *) {
            let safe = ThreadSafe()
            
            let e = expectation(description: "Thread Safe")
            
            DispatchQueue.concurrentPerform(iterations: 1000) { iteration in
                safe.execute {
                    array.append(iteration)
                    
                    if array.count == 1000  {
                        e.fulfill()
                    }
                }
            }
            
            wait(for: [e], timeout: 5)
        }
    }
    
    func testThreadSafeLegacy() {
        
        let safe = ThreadSafeLegacy()
        let e = expectation(description: "Thread Safe Legacy")

        DispatchQueue.concurrentPerform(iterations: 1000) { iteration in
            safe.execute {
                array.append(iteration)
                
                if array.count == 1000  {
                    e.fulfill()
                }
            }
        }
        
        wait(for: [e], timeout: 5)
    }
}
