//
//  ContentView.swift
//  AuthSampleApp
//
//  Created by Shamal nikam on 1/8/26.
//

import SwiftUI

struct ContentView: View {
    var viewModel: ContentViewModel
    
    var body: some View {
        VStack {
            Button {
                viewModel.authenticateWithAuth0()
            } label: {
                Text("Authenticate With Auth0")
            }

//            Text("GitHub")
//                .onTapGesture {
//                    viewModel.authenticateWithGitHub()
//                }
        }.onAppear{
            
        }
        .padding()
    }
}
