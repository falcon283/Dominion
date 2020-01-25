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

class GitHub: HTTPService<HTTPDataProvider> {
        
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


//class GitHub {
//
//    typealias GitHubResourceConfiguration<T> = URLRequestConfiguration<T, GitHubAPIError>
//    typealias GitHubResource<T> = Resource<GitHubResourceConfiguration<T>, HTTPDataProvider>
//
//    private let session = URLSession(configuration: .default)
//    private lazy var provider: HTTPDataProvider = {
//        let provider = HTTPDataProvider(with: self.session)
//        provider.commonHeaders = ["Accept": "application/vnd.github.v3+json"]
//        return provider
//    }()
//
//    private let safe = platformSafe
//    private var resources: [String: Any] = [:]
//
//    func getResource<T: Codable>(with configuration: GitHubResourceConfiguration<T>,
//                                         identifier: String,
//                                         function: String = #function) -> GitHubResource<T> {
//
//        let id = "\(identifier)-\(function)"
//        return (resources[id] as? GitHubResource<T>) ?? createResource(with: configuration, identifier: id)
//    }
//
//    private func createResource<T: Codable>(with configuration: GitHubResourceConfiguration<T>,
//                                            identifier: String) -> GitHubResource<T> {
//
//        let resource = GitHubResource(with: configuration, using: provider)
//        safe.execute {
//            resources[identifier] = resource
//        }
//        return resource
//    }
//
//    static let decoder: JSONDecoder = {
//        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//        decoder.dateDecodingStrategy = .iso8601
//        return decoder
//    }()
//
//    static let encoder: JSONEncoder = {
//        let encoder = JSONEncoder()
//        encoder.keyEncodingStrategy = .convertToSnakeCase
//        encoder.dateEncodingStrategy = .iso8601
//        return encoder
//    }()
//}
