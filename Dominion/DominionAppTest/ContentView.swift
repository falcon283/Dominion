//
//  ContentView.swift
//  DominionAppTest
//
//  Created by Gabriele Trabucco on 23/01/2020.
//  Copyright © 2020 Gabriele Trabucco. All rights reserved.
//

import SwiftUI
import Combine
import Dominion

extension View {
    var asAnyView: AnyView {
        AnyView(self)
    }
}

class ReposViewModel: ObservableObject {
    
    var objectWillChange = ObservableObjectPublisher()
    
    @Published
    var searchText: String = ""
    
    private var token: Cancellable?
    
    var repos: [GitHubRepo] = [] {
        willSet {
            objectWillChange.send()
        }
    }
    
    init() {
        token = $searchText
            .filter { $0.count > 2 }
            .debounce(for: 0.5, scheduler: DispatchQueue.main, options: nil)
            .map { Container.gitHub.repos(for: $0).publisher.replaceError(with: .value([])) }
            .switchToLatest()
            .eraseToAnyPublisher()
            .print()
            .sink { [weak self] in self?.repos = $0.value ?? [] }
    }
}

struct ContentView: View {
    
    @ObservedObject
    var viewModel = ReposViewModel()
        
    @State
    var searchText: String = ""
    
    var body: some View {
        
        VStack {
            TextField("Handle Name", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            if viewModel.repos.isEmpty {
                VStack {
                    Spacer()
                    Text("No Repository")
                    Spacer()
                }
            } else {
                List(viewModel.repos) {
                    Text($0.name ?? "NoName")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
