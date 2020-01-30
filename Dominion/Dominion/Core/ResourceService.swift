//
//  ResourceService.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 24/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

open class ResourceService<P: ResourceProvider> {
    
    private let provider: P
    private let safe = platformSafe
    private var resources: [String: Any] = [:]
    
    public init(provider: P) {
        self.provider = provider
    }
    
    public func getResource<C: ResourceConfiguration>(for configuration: C) -> Resource<C, P> {
        if let id = configuration.cacheIdentifier {
            return (resources[id] as? Resource<C, P>) ?? createResource(with: id, using: configuration)
        } else {
            return createResource(with: nil, using: configuration)
        }
    }
    
    private func createResource<C: ResourceConfiguration>(with identifier: String?,
                                                          using configuration: C) -> Resource<C, P> {
        
        let resource = Resource(with: configuration, using: provider)
        if let id = identifier {
            safe.execute {
                resources[id] = resource
            }
        }
        return resource
    }
}