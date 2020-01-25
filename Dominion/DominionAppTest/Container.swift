//
//  Container.swift
//  DominionAppTest
//
//  Created by Gabriele Trabucco on 23/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import Foundation
import Dominion

enum Container {
    
    static let gitHub = GitHub(provider: .init(with: URLSession(configuration: .default)))
}
