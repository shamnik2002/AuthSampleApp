//
//  Parser.swift
//  AuthSampleApp
//
//  Created by Shamal nikam on 1/8/26.
//

import Foundation

protocol ParseProtocol {
    func parse<T: Codable>(data: Data, type: T.Type) throws -> T
}

final class Parser: ParseProtocol {
    func parse<T: Codable>(data: Data, type: T.Type) throws -> T {
        
        do {
            let result = try JSONDecoder().decode(T.self, from: data)
            return result
        }catch {
            // log error
            throw error
        }
    }
}
