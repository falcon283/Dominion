//
//  Dictionary+Merge.swift
//  Dominion
//
//  Created by Gabriele Trabucco on 19/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation

public extension Dictionary {
    
    // Merge, right values override left values
    static func +(lhs: Self, rhs: Self) -> Self {
        lhs.merging(rhs) { $1 }
    }
}
