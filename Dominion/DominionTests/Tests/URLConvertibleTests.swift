//
//  URLConvertibleTests.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 23/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import XCTest

import Dominion

class URLConvertibleTests: XCTestCase {

    func testUrl() {
        
        let url = URL(string: "https://www.google.com")!
        
        XCTAssert(url == url.asUrl, "Url should be intrinsically UrlConvertible")
    }

}
