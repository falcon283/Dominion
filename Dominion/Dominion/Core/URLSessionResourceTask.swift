//
//  URLSessionResourceTask.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

/// A ResourceTask suitable for URLSesssion requests.
class URLSessionResourceTask: ResourceTask {
    
    private let task: URLSessionTask
    
    /// Designated initializer
    /// - Parameter task: The task to wrap.
    init(with task: URLSessionTask) {
        self.task = task
    }
    
    var progress: Double {
        if #available(iOS 11.0, *) {
            return task.progress.fractionCompleted
        } else {
            return min(max(0, Double(task.countOfBytesReceived) / Double(task.countOfBytesExpectedToReceive)), 1)
        }
    }
    
    func resume() {
        task.resume()
    }
    
    func suspend() {
        task.suspend()
    }
    
    func cancel() {
        task.cancel()
    }
}
