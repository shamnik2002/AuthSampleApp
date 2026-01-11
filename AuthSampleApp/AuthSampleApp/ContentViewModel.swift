//
//  ContentViewModel.swift
//  AuthSampleApp
//
//  Created by Shamal nikam on 1/10/26.
//

import Foundation
import Combine

final class ContentViewModel: ObservableObject {
    
    let authService = Auth0Service(networkService: NetworkService(), parser: Parser())
    let gitHubService = GitAuthService(networkService: NetworkService(), parser: Parser())

    func authenticateWithAuth0() {
        Task {
            do {
                let access_token = try await authService.authenticate()
                print(access_token)
            }catch {
                print("error")
            }
        }
    }
    
    func authenticateWithGitHub() {
        Task {
            do {
                let access_token = try await gitHubService.authenticate()
                print(access_token)
            }catch {
                print("error")
            }
        }
    }
}
