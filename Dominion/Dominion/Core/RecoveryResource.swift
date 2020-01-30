//
//  RecoveryResource.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 21/02/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// Internal Resource subclass able to perform recovery for the wrapping Resource using a recovery Resource. It's accessible via Resource.recover extension
class RecoveryResource<CR: ResourceConfiguration, C: ResourceConfiguration, P: ResourceProvider>: Resource<C, P> where C.Request == CR.Request, CR.Request == P.Request {
        
    private let recoveryResource: Resource<CR, P>
    private let shouldRecovery: (Result<Response<C.Downstream>, Error>) -> Bool
    private let recover: (Response<CR.Downstream>) -> Void

    private weak var recoveryToken: CancellationTokenBag?

    @available(*, unavailable)
    override init(with configuration: C, using provider: P) {
        fatalError()
    }
    
    init(with configuration: C,
         using provider: P,
         recoveryResource resource: Resource<CR, P>,
         shouldRecovery: @escaping (Result<Response<C.Downstream>, Error>) -> Bool,
         recovery: @escaping (Response<CR.Downstream>) -> Void) {
        self.recoveryResource = resource
        self.recover = recovery
        self.shouldRecovery = shouldRecovery
        super.init(with: configuration, using: provider)
    }
    
    override var isRunning: Bool {
        super.isRunning || recoveryResource.isRunning
    }
            
    override func observe(with callback: @escaping ObservationCallback<Response<C.Downstream>>) -> CancellationToken {
                
        let bag = CancellationTokenBag()
        let token = super.observe { [weak self] result in
            guard let self = self else { return }
            
            let handleRecover = {
                self.safe.execute {
                    if self.recoveryToken == nil {
                        let token = self.performRecovery(for: result, with: callback)
                        bag.append(token)
                    } else {
                        self.safe.execute { self.recoveryToken = nil }
                        callback(result)
                    }
                }
            }
            
            switch result {
            case .success(let response):
                switch response {
                case .value, .emptyValue:
                    self.safe.execute { self.recoveryToken = nil }
                    callback(result)
                    
                case .error, .emptyError:
                    handleRecover()
                }
                
            case .failure:
                handleRecover()
            }
        }
        bag.append(token)
        
        return bag
    }
            
    private func performRecovery(for result: Result<Response<C.Downstream>, Error>,
                                 with callback: @escaping ObservationCallback<Response<C.Downstream>>) -> CancellationToken {
        
        if shouldRecovery(result) {
            let bag = CancellationTokenBag()
            recoveryToken = bag
            let token = self.recoveryResource.observe { [weak self] recoveryResult in
                
                switch recoveryResult {
                case .success(let response):
                    switch response {
                    case .value, .emptyValue:
                        self?.recover(response)
                        self?.refresh()
                        
                    case .error, .emptyError:
                        self?.safe.execute { self?.recoveryToken = nil }
                        callback(result)
                    }
                case .failure:
                    self?.safe.execute { self?.recoveryToken = nil }
                    callback(result)
                }
            }
            bag.append(token)
            return bag
        } else {
            callback(result)
            return NoOpCancellationToken()
        }
    }
}
