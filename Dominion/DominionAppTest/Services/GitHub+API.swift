//
//  GitHub+API.swift
//  DominionAppTest
//
//  Created by Gabriele Trabucco on 24/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

extension GitHub {
    
    func repos(for username: String) -> GitHubResource<[GitHubRepo]> {
        getResource(for: GitHubResourceConfiguration(route: GitHubRouter.myRepos(username: username),
                                                     expiration: .interval(60),
                                                     downstream: .init(decoder: Self.decoder)))
        .withGitHubAuthRevovery()
    }
    
}
