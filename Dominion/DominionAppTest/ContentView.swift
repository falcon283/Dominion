//
//  ContentView.swift
//  DominionAppTest
//
//  Created by Gabriele Trabucco on 23/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import SwiftUI

var tokens = [CancellationToken]()

struct ContentView: View {
    
    var body: some View {
        
        Button(action: {
            Container.gitHub.repos(for: "falcon283")
                .observe { print($0) }
                .store(in: &tokens)
            
        }, label: {
            Text("Hello World!")
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
