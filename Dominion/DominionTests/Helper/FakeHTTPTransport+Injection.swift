//
//  FakeHTTPTransport+Injection.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

@testable import Dominion

extension FakeHTTPTransport {
    func inject<O, E: Error>(_ configuration: URLRequestConfiguration<O, E>, data: Data?, statusCode: Int) {
        let isValid = 200..<300 ~= statusCode
        addFakeResponse((data,
                         HTTPURLResponse(url: Routes.user.asUrl!,
                                         statusCode: statusCode,
                                         httpVersion: nil,
                                         headerFields: nil),
                         isValid ? nil : FakeHTTPTransportError.genericError),
                        for: try! configuration.request())
    }
}
