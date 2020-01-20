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

struct WrongData: Codable {
    let unknown: String
}

struct ApiError: Codable, Error {
    let code: Int
}

extension Result where Success == Response<User> {
    
    var response: Response<User>? {
        switch self {
        case .success(let response):
            return response
        case .failure:
            return nil
        }
    }
}

extension Result where Success == Response<Void> {
    
    var response: Response<Void>? {
        switch self {
        case .success(let response):
            return response
        case .failure:
            return nil
        }
    }
}
