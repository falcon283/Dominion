//
//  RetryResource.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 21/02/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

private extension Int {
    static let none = -1
}

/// Internal Resource subclass able to perform retry on top of a wrapped Resource. It's accessible via Resource.retryOnError extension
class RetryResource<C: ResourceConfiguration, P: ResourceProvider>: Resource<C, P> where C.Request == P.Request {

    private let shouldRetry: (Result<Response<C.Downstream>, Error>) -> Bool
    private let retry: RetryClosure

    private var attempt = Int.none
    private weak var retryToken: CancellationToken?

    @available(*, unavailable)
    override init(with configuration: C, using provider: P) {
        fatalError()
    }
    
    init(with configuration: C,
         using provider: P,
         shouldRetry: @escaping (Result<Response<C.Downstream>, Error>) -> Bool,
         retry: @escaping RetryClosure) {
        
        self.shouldRetry = shouldRetry
        self.retry = retry
        super.init(with: configuration, using: provider)
    }
    
    override var isRunning: Bool {
        super.isRunning || retryToken != nil
    }
    
    override func observe(with callback: @escaping ObservationCallback<Response<C.Downstream>>) -> CancellationToken {
                
        let bag = CancellationTokenBag()
        let token = super.observe { [weak self] result in
            guard let self = self else { return }
            
            let handleRetry = {
                self.safe.execute {
                    if self.retryToken == nil {
                        let token = self.performRetry(for: result, with: callback)
                        bag.append(token)
                    } else {
                        self.safe.execute { self.retryToken = nil }
                        callback(result)
                    }
                }
            }
            
            switch result {
            case .success(let response):
                switch response {
                case .value, .emptyValue:
                    self.safe.execute { self.retryToken = nil }
                    callback(result)
                    
                case .error, .emptyError:
                    handleRetry()
                }
                
            case .failure:
                handleRetry()
            }
        }
        bag.append(token)
        
        return bag
    }
        
    private func performRetry(for result: Result<Response<C.Downstream>, Error>,
                              with callback: @escaping ObservationCallback<Response<C.Downstream>>) -> CancellationToken {
        
        if shouldRetry(result) {
            attempt += 1
            let retryToken = retry(UInt(attempt)) { [weak self] in
                self?.safe.execute {
                    self?.retryToken = nil
                    self?.refresh()
                }
            }
            self.retryToken = retryToken
            if let token = retryToken {
                return token
            } else {
                attempt = .none
                callback(result)
                return NoOpCancellationToken()
            }
        } else {
            retryToken = nil
            attempt = .none
            callback(result)
            return NoOpCancellationToken()
        }
    }
}
