//
//  ResourceTask.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// A ResourceTask is an object that handle the Network activity of a particular request. It's usefull to handle the request or keep track of the progress.
public protocol ResourceTask {
    /// Cancel the request.
    func cancel()
    
    /// Suspend the request for later resume.
    func suspend()
    
    /// Resume a request.
    func resume()
    
    /// The progress of the request.
    var progress: Double { get }
}
