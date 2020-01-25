//
//  GitHubAPIError.swift
//  DominionAppTest
//
//  Created by Gabriele Trabucco on 23/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

// MARK: - GitHubAPIError
struct GitHubAPIError: Codable, Error {
    
    // MARK: - Error
    struct Error: Codable {
        let resource: String?
        let field: String?
        let code: String?
    }
    
    let message: String?
    let errors: [Error]?
}

