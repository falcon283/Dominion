//
//  TestsType.swift
//  DominionTests
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation
import Dominion

enum Routes {
    case user
}

extension Routes: URLConvertible {
    var asUrl: URL {
        switch self {
        case .user:
            return URL(string: "https://fakeurl.com/me")!
        }
    }
}

struct User: Codable {
    let name: String
}
