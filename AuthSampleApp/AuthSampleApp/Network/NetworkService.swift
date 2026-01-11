//
//  NetworkService.swift
//  AuthSampleApp
//
//  Created by Shamal nikam on 1/8/26.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case authError
    case forbiddenError
    case serverError
    case unknownError
}

protocol NetworkProtocol {
    
    func fetchData(request: RequestProtocol) async throws -> Data
}

final class NetworkService: NetworkProtocol {
    
    var session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchData(request: RequestProtocol) async throws -> Data {
        
        let urlRequest = try request.buildRequest()
        
        let response = try await session.data(for: urlRequest)
        
        guard let httpResponse = response.1 as? HTTPURLResponse else {
            throw NetworkError.unknownError
        }
        
        switch httpResponse.statusCode {
            case 200...299: return response.0
            case 500...599: throw NetworkError.serverError
            case 401: throw NetworkError.authError
            case 403: throw NetworkError.forbiddenError
            default: throw NetworkError.unknownError
        }
    }
}
