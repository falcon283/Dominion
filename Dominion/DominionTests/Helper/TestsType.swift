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
            return URL(string: "https://api.myjson.com/bins/vlg10")!
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

var userData: Data {
    try! JSONEncoder().encode(User(name: "Gabriele"))
}

var wrongData: Data {
    try! JSONEncoder().encode(WrongData(unknown: "unknown"))
}

var apiErrorData: Data {
    try! JSONEncoder().encode(ApiError(code: 1234))
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
