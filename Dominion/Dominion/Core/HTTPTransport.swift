//
//  HTTPTransport.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public protocol HTTPTransport {
    
    func task(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> ResourceTask
}
