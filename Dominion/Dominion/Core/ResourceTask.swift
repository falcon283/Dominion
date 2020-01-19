//
//  ResourceTask.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public protocol ResourceTask {
    func cancel()
    func suspend()
    func resume()
    
    var progress: Double { get }
}
