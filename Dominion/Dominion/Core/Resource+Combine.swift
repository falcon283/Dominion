//
//  Resource+Combine.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 23/02/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public extension Publishers {
    
    /// A Combine Resource Publisher.
    struct ResourcePublisher<C: ResourceConfiguration, P: ResourceProvider>: Publisher where C.Request == P.Request {
        
        private class ResourceSubscription<C: ResourceConfiguration, P: ResourceProvider>: Subscription where C.Request == P.Request {
            
            private var observationToken: CancellationToken?
            private var refreshToken: Cancellable?
            
            private let resource: Resource<C, P>
            private let refresher: AnyPublisher<Void, Never>?
            private let observeAction: (Result<Response<C.Downstream>, Error>) -> Void
            
            init(for resource: Resource<C, P>,
                 refresher: AnyPublisher<Void, Never>?,
                 observation: @escaping (Result<Response<C.Downstream>, Error>) -> Void) {
                
                self.resource = resource
                self.refresher = refresher
                self.observeAction = observation
            }
            
            func request(_ demand: Subscribers.Demand) {
                observationToken = resource.observe(with: observeAction)
                refreshToken = refresher?.sink { [weak self] _ in self?.resource.refresh() }
            }
            
            func cancel() {
                observationToken = nil
                refreshToken?.cancel()
                refreshToken = nil
            }
        }
        
        public typealias Output = Result<Response<C.Downstream>, Error>
        public typealias Failure = Never
        
        private let resource: Resource<C, P>
        private let refresher: AnyPublisher<Void, Never>?
        
        /// Designated initializer
        /// - Parameters:
        ///   - resource: The resource to observe.
        ///   - refresher: The refresh trigger.
        public init(_ resource: Resource<C, P>, refresher: AnyPublisher<Void, Never>? = nil) {
            self.resource = resource
            self.refresher = refresher
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = ResourceSubscription(for: resource, refresher: refresher) { _ = subscriber.receive($0) }
            subscriber.receive(subscription: subscription)
        }
    }
}

@available(iOS 13.0, *)
/// A Combine ObservableObject useful for SwiftUI..
public class ObservableResource<T>: ObservableObject {
    
    private let resource: Any
    
    private var observationToken: CancellationToken?
    private var refreshToken: Cancellable?

    public var objectWillChange = ObservableObjectPublisher()
    public private(set) var result: Result<Response<T>, Error>? {
        willSet {
            objectWillChange.send()
        }
    }
    
    /// Designated initializer
    /// - Parameters:
    ///   - resource: The resource to observe.
    ///   - refresher: The refresh trigger.
    fileprivate init<C: ResourceConfiguration, P: ResourceProvider>(_ resource: Resource<C, P>,
                                                                    using refresh: AnyPublisher<Void, Never>? = nil)
        where C.Request == P.Request, C.Downstream == T {
            
            self.resource = resource
            self.observationToken = resource.observe { [weak self] in
                self?.result = $0 }
            self.refreshToken = refresh?.sink { _ in resource.refresh() }
    }
}

@available(iOS 13.0, *)
public extension Resource {
    
    /// The resource Combine Publisher.
    /// - Parameter refresh: The refresh trigger.
    /// - Returns: The Combine Resource to observe.
    func publisher(using refresh: AnyPublisher<Void, Never>? = nil) -> Publishers.ResourcePublisher<C, P> {
        Publishers.ResourcePublisher(self, refresher: refresh)
    }

    /// The resource Observabel object useful for SwiftUI..
    /// - Parameter refresh: The refresh trigger.
    /// - Returns: The Resource Observer to use in SwiftUI.
    func observableObject(using refresh: AnyPublisher<Void, Never>? = nil) -> ObservableResource<C.Downstream> {
        ObservableResource(self, using: refresh)
    }
}
