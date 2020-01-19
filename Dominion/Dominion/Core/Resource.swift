//
//  Resource.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public class Resource<C: ResourceConfiguration, P: ResourceProvider> where C.Request == P.Request {
    
    private let safe = platformSafe
    private var observers: [ResourceObserver<Response<C.Downstream>>] = []
    private let provider: P
    private let configuration: C
    
    private var task: ResourceTask?
    private var taskResult: Result<Response<C.Downstream>, Error>? {
        didSet {
            switch taskResult {
            case .success(let response):
                switch response {
                case .value, .empty:
                    resultDate = Date()
                case .error:
                    resultDate = nil
                }
            case .failure, .none:
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
    
    private var isRunning: Bool {
        self.task != nil
    }
 
    public func observe(with callback: @escaping ObservationCallback<Response<C.Downstream>>) -> CancellationToken {
        addObserver(callback)
    }

    public func refresh() {
        safe.execute {
            guard isRunning == false else { return }
            perform(with: configuration.aggressiveConfiguration())
        }
    }
        
    private func perform(with observer: ResourceObserver<Response<C.Downstream>>) {
        
        // If running let the task complete and all the observers will be notified.
        guard isRunning == false else { return }
        
        if isResourceExpired {
            perform(with: configuration.aggressiveConfiguration())
        } else if let result = taskResult {
            observer.emit(result)
        } else {
            perform(with: configuration)
        }
    }
    
    private func perform(with configuration: C) {
        let task = provider.perform(using: configuration) { [weak self] result in
            self?.safe.execute {
                self?.taskResult = result
                self?.observers.forEach { $0.emit(result) }
                self?.task = nil
            }
        }
        self.task = task
        task.resume()
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
