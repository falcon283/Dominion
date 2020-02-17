//
//  Resource.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation


/// A Resource is the central object in Dominion. Once obtained can be observed for future updates.
public class Resource<C: ResourceConfiguration, P: ResourceProvider> where C.Request == P.Request {
    
    /// The internal status of the resoirce
    enum ResourceState {
        
        /// Initial status
        case initial
        
        /// Resource has data to provide externally.
        case data(Response<C.Downstream>)
        
        /// The Resource is in error state.
        case error(Error)
    }
    
    private let safe = platformSafe
    private var observers: [ResourceObserver<Response<C.Downstream>>] = []
    private let provider: P
    private let configuration: C
    
    private var task: ResourceTask?
    
    private(set) var state: ResourceState = .initial {
        didSet {
            switch state {
            case .data(let response):
                switch response {
                case .value, .emptyValue:
                    resultDate = Date()
                case .error, .emptyError:
                    resultDate = nil
                }
            case .error, .initial:
                resultDate = nil
            }
        }
    }
    
    private var resultDate: Date?
    
    /// Designated initializer.
    /// - Parameters:
    ///   - configuration: The configuration of the resource.
    ///   - provider: The provider for the resource.
    public init(with configuration: C, using provider: P) {
        self.configuration = configuration
        self.provider = provider
    }
    
    /// True if resource is expired. The expiration behaviour is based on the configuration.
    var isResourceExpired: Bool {
        
        switch configuration.expiration {
        case .never:
            return false
        
        case .interval(let interval):
            guard let pastDate = resultDate else { return true }
            return Date().timeIntervalSince(pastDate) >= interval
            
        case .date(let expirationDate):
            return Date() >= expirationDate
        }
    }
    
    /// True if the resource is in the request process and it's waiting for a result.
    var isRunning: Bool {
        self.task != nil
    }
    
    /// Attach an external observer to the resource. Multiple observers can be added susequently. The first attached observer makes the resource load.
    /// Subsequent observer will trigger a reload based on the expiration behaviour. If the resource is not yet expired and is not in error, a subsequent attached
    /// observer will immediately receive the given underlying result.
    /// - Parameter callback: The given callback is the observer for the resource. The block is kept alive untill the CancellationToken is deallocated.
    /// - Returns: A memory management object. Once the token is deallocated, the callback is destroyed and will not be called anymore in case of
    /// subsequent updates.
    public func observe(with callback: @escaping ObservationCallback<Response<C.Downstream>>) -> CancellationToken {
        addObserver(callback)
    }
    
    /// Force the refresh of the resource. It's force a reload of the resource disregarding the expiration  behaviour.
    public func refresh() {
        safe.execute {
            guard observers.count > 0, isRunning == false else { return }
            perform(with: configuration.aggressiveConfiguration())
        }
    }
        
    private func perform(with observer: ResourceObserver<Response<C.Downstream>>) {
        
        // If running let the task complete and all the observers will be notified.
        guard isRunning == false else { return }
        
        switch state {
        case .initial:
            perform(with: configuration.aggressiveConfiguration())
        case .data(let response):
            if isResourceExpired {
                perform(with: configuration.aggressiveConfiguration())
            } else {
                observer.emit(.success(response))
            }
        case .error:
            perform(with: configuration)
        }
    }
    
    private func updateState(with result: Result<Response<C.Downstream>, Error>) {
        switch result {
        case .success(let response):
            state = .data(response)
        case .failure(let error):
            state = .error(error)
        }
    }
    
    private func perform(with configuration: C) {
        do {
            let task = try provider.perform(using: configuration) { [weak self] result in
                self?.safe.execute {
                    self?.updateState(with: result)
                    
                    self?.observers.forEach { $0.emit(result) }
                    // In this place because to avoid endless loop starting a refresh
                    // or another addObserver from the observer emission.
                    self?.task = nil
                }
            }
            self.task = task
            task.resume()
        } catch {
            let result: Result<Response<C.Downstream>, Error> = .failure(error)
            self.updateState(with: result)
            self.observers.forEach { $0.emit(result)}
        }
    }
    
    private func addObserver(_ callback: @escaping ObservationCallback<Response<C.Downstream>>) -> CancellationToken {
        let observer = ResourceObserver(block: callback)
        safe.execute {
            observers.append(observer)
            perform(with: observer)
        }
        
        return DeinitCancellationToken { [weak self] in self?.removeObserver(with: observer.id) }
    }
    
    private func removeObserver(with identifier: ObjectIdentifier) {
        safe.execute {
            let index = observers.firstIndex { $0.id == identifier }
            guard let i = index else { return }
            observers.remove(at: i)
            
            if observers.count == 0 {
                task?.cancel()
                task = nil
            }
        }
    }
}

import Combine

@available(iOS 13.0, *)
public class CombineResource<T>: ObservableObject {
    
    private var token: CancellationToken?

    public var objectWillChange = ObservableObjectPublisher()
    public private(set) var response: Response<T>? {
        willSet {
            guard newValue != nil else { return }
            self.error = nil
        }
    }
    
    public private(set) var error: Error? {
        willSet {
            objectWillChange.send()
        }
    }
    
    fileprivate init<C: ResourceConfiguration, P: ResourceProvider>(_ resource: Resource<C, P>)
        where C.Request == P.Request, C.Downstream == T {
            
            self.token = resource.observe(with: { [weak self] in
                switch $0 {
                case .success(let response):
                    self?.response = response
                case .failure(let error):
                    self?.error = error
                }
            })
    }
}

@available(iOS 13.0, *)
public extension Resource {
    
    var publisher: AnyPublisher<Response<C.Downstream>, Error> {
        let publisher = PassthroughSubject<Response<C.Downstream>, Error>()
        let token = self.observe {
            switch $0 {
            case .success(let response):
                publisher.send(response)
            case .failure(let error):
                publisher.send(completion: .failure(error))
            }
        }
        return AnyPublisher(publisher.handleEvents(receiveCompletion: { _ in _ = token }))
    }
    
    var combineResource: CombineResource<C.Downstream> { CombineResource(self) }
}
