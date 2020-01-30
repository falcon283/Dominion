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
