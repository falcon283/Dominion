//
//  FakeHTTPTransport+Injection.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

import Dominion

extension FakeHTTPTransport {
    func inject<O, E: Error>(_ configuration: URLRequestConfiguration<O, E>, data: Data?, statusCode: Int) {
        let isValid = 200..<300 ~= statusCode
        addFakeResponse((isValid ? data : nil,
                         HTTPURLResponse(url: Routes.user.asUrl,
                                         statusCode: 200,
                                         httpVersion: nil,
                                         headerFields: nil),
                         isValid ? nil : NSError(domain: "FakeProvider", code: statusCode, userInfo: nil)),
                        for: configuration.request)
    }
}
