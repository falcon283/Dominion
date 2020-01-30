//
//  ResourceService.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 24/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// The ResourceService responsability is to centralize the acces of the Resources. This way the Resources are alive within the service and, if retrieved multiple times,
/// the underlaying response and expiration behaviour will be shared across the multiple users. The class is open to let the Application Layer to make custom
/// subsclassis and facilitate even more the access to the resources based on it' custom requirement.
open class ResourceService<P: ResourceProvider> {
    
    private let provider: P
    private let safe = threadSafe()
    private var resources: [String: Any] = [:]
    
    /// Designated initializer
    /// - Parameter provider: The provider the service will user for all the resources handled by this instance.
    public init(provider: P) {
        self.provider = provider
    }
    
    /// Retrieve a resource using the given configuration. If the resource is not yet available get created and stored internally for future reuse.
    /// - Parameter configuration: The configuration for the given resource.
    /// - Returns: The resource object.
    /// - Note: Mind that subsequent access will use the cacheIdentifier of the configuration in order to search an already internally stored resource.
    /// If the configuration parameters are different from the original one, they will be ignored and the original configuration parameters are used.
    public func getResource<C: ResourceConfiguration>(for configuration: C) -> Resource<C, P> {
        if let id = configuration.cacheIdentifier {
            return (resources[id] as? Resource<C, P>) ?? createResource(with: id, using: configuration)
        } else {
            return createResource(with: nil, using: configuration)
        }
    }

    /// See `getResource`
    public subscript<C: ResourceConfiguration>(resource configuration: C) -> Resource<C, P> {
        getResource(for: configuration)
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
