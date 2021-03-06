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

extension GitHub {
    
    func authRefresh(for token: String) -> GitHubResource<AuthToken> {
        getResource(for: GitHubResourceConfiguration(route: GitHubRouter.authorizationRefresh,
                                                     headers: ["Auth": token],
                                                     cachePolicy: .reloadIgnoringLocalCacheData,
                                                     downstream: .init(decoder: Self.decoder)))
    }


}

struct AuthToken: Decodable {
    let token: String
}

extension Resource where P == HTTPDataProvider {
    
    func withGitHubAuthRevovery() -> Resource<C, P> {
        recover(using: Container.gitHub.authRefresh(for: "token"),
                shouldRecovery: { _ in true },
                recovery: { _ in /* Container.gitHub.updateToken */ })
    }
}

