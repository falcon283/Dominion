//
//  HTTPTransport.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// An HTTPProtocol is an object responsible for the execution of the row URL request and receive the incoming data or error.
public protocol HTTPTransport {
    
    /// Execute the network task and wait for incoming data.
    /// - Parameters:
    ///   - request: The network request to send.
    ///   - completion: A completion object responsible to handle the incoming data, inspecting the response and handle the error eventually.
    ///   - data: the incoming data of the request
    ///   - response: The URLResponse of the reuqest.
    ///   - error: The error of the request.
    /// - Returns: The resource task to use to handle the network request.
    func task(with request: URLRequest,
              completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) -> ResourceTask
}
