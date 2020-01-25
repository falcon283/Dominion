//
//  GitHubRouter.swift
//  DominionAppTest
//
//  Created by Gabriele Trabucco on 23/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation
import Dominion

enum GitHubRouter {
    
    case myRepos(username: String)
}

extension GitHubRouter: URLConvertible {
    
    private static let schema = "https"
    private static let host = "api.github.com"
    
    private static let components: URLComponents = {
        var components = URLComponents()
        components.scheme = schema
        components.host = host
        return components
    }()
    
    var asUrl: URL {
        switch self {
        case .myRepos(username: let name):
            var c = Self.components
            c.path = "/users/\(name)/repos"
            return c.url!
        }
    }
}
