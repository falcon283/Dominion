//
//  Resource.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation


public class Resource<C: ResourceConfiguration, P: ResourceProvider> where C.Request == P.Request {
    
    enum ResourceState {
        case initial
        case data(Response<C.Downstream>)
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
    
    public init(with configuration: C, using provider: P) {
        self.configuration = configuration
        self.provider = provider
    }
    
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
    
    var isRunning: Bool {
        self.task != nil
    }
 
    public func observe(with callback: @escaping ObservationCallback<Response<C.Downstream>>) -> CancellationToken {
        addObserver(callback)
    }

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
