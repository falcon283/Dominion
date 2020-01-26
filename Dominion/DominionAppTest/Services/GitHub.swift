//
//  GitHub.swift
//  DominionAppTest
//
//  Created by Gabriele Trabucco on 23/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation
import Dominion

typealias CancellationToken = Dominion.CancellationToken

class GitHub: ResourceService<HTTPDataProvider> {
        
    typealias GitHubResourceConfiguration<T> = URLRequestConfiguration<T, GitHubAPIError>
    typealias GitHubResource<T> = Resource<GitHubResourceConfiguration<T>, HTTPDataProvider>
    
    override init(provider: HTTPDataProvider) {
        provider.commonHeaders = ["Accept": "application/vnd.github.v3+json"]
        super.init(provider: provider)
    }
    
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
