//
//  HTTPService.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 24/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

open class HTTPService<P: ResourceProvider> {
    
    private let provider: P
    private let safe = platformSafe
    private var resources: [String: Any] = [:]
    
    public init(provider: P) {
        self.provider = provider
    }
    
    public func getResource<C: ResourceConfiguration>(for configuration: C) -> Resource<C, P> {
        let id = configuration.identifier
        return (resources[id] as? Resource<C, P>) ?? createResource(with: id, using: configuration)
    }
    
    private func createResource<C: ResourceConfiguration>(with identifier: String,
                                                          using configuration: C) -> Resource<C, P> {
        
        let resource = Resource(with: configuration, using: provider)
        safe.execute {
            resources[identifier] = resource
        }
        return resource
    }
}
