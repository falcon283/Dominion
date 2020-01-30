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
    
    let safe = recursiveThreadSafe()
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
        
    fileprivate func perform(with observer: ResourceObserver<Response<C.Downstream>>) {
        
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
                    self?.task = nil
                    self?.observers.forEach { $0.emit(result) }
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

public extension Resource {
    
    private static func retry(_ maxAttempts: Int, retryFunction: RetryTimeFunction) -> RetryClosure {
        retry(maxAttempts, timeFunction: retryFunction.timeFunction)
    }
    
    /// Utility to create a RetryClosure with a custom Retry Closure
    /// - Parameters:
    ///   - maxAttempts: The max attempts to retry
    ///   - timeFunction: The time function to perform the retry after a certain amount of time.
    /// - Returns: The RetryClosure with the given custom time function.
    static func retry(_ maxAttempts: Int, timeFunction: @escaping RetryTime) -> RetryClosure {
        return { attempt, refresh in
            guard attempt < maxAttempts else { return nil }
            let queue = DispatchQueue(label: "it.gtrabucco.dominion.resource.retry.queue")
            let delay = timeFunction(attempt)
            let workItem = DispatchWorkItem(block: refresh)
            queue.asyncAfter(wallDeadline: .now() + .milliseconds(Int(delay) * 1000), execute: workItem)
            return DeinitCancellationToken { workItem.cancel() }
        }
    }
    
    /// Utility to make a Resource able to recover with custom rules using a different Resource.
    /// - Parameters:
    ///   - resource: The resource to use for the recovery process. (e.g authentication token recovery)
    ///   - shouldRecovery: A closure to filter certain types of errors. Default always true.
    ///   - recovery: The closure to run when the recovery rosource succeed. You are responsible to use the response to update your app state and
    ///   make your original resource retry to succeede
    /// - Returns: The wrapped resource able to recover
    func recover<R, CW>(using resource: R,
                        shouldRecovery: @escaping (Result<Response<C.Downstream>, Error>) -> Bool = { _ in true },
                        recovery: @escaping (Response<CW.Downstream>) -> Void) -> Resource<C, P>
        where CW: ResourceConfiguration, R: Resource<CW, P> {
        
        RecoveryResource(with: configuration,
                         using: provider,
                         recoveryResource: resource,
                         shouldRecovery: shouldRecovery,
                         recovery: recovery)
    }
    
    /// Utility to make a Resource able to retry with custom rules using a custom RetryClosure.
    /// - Parameters:
    ///   - shouldRetry: A closure to filter certain types of errors. Default always true.
    ///   - retry: The custom RetryClosure to offset subsequents retry attempts.
    /// - Returns: The wrapped resource able to retry
    func retryOnError(if shouldRetry: @escaping (Result<Response<C.Downstream>, Error>) -> Bool = { _ in true },
                      with retry: @escaping RetryClosure) -> Resource<C, P> {
        
            RetryResource(with: configuration,
                          using: provider,
                          shouldRetry: shouldRetry,
                          retry: retry)
    }
    
    /// Utility to make a Resource able to retry using max attemps and a built in RetryFunction.
    /// - Parameters:
    ///   - attempts: The max attemps to retry.
    ///   - retryFunction: The time function to use to offset subsequents retry attempts
    ///   - shouldRetry: A closure to filter certain types of errors. Default always true.
    /// - Returns: The wrapped resource able to retry
    func retryOnError(_ attempts: Int,
                      in retryFunction: RetryTimeFunction,
                      if shouldRetry: @escaping (Result<Response<C.Downstream>, Error>) -> Bool = { _ in true }) -> Resource<C, P> {
        
        retryOnError(if: shouldRetry, with: Resource.retry(attempts, retryFunction: retryFunction))
    }
}
