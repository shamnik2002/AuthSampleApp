//
//  RequestProtocol.swift
//  AuthSampleApp
//
//  Created by Shamal nikam on 1/8/26.
//

import Foundation


enum Scheme: String {
    case https
}

enum HttpMethod: String {
    case GET
    case POST
}

protocol RequestProtocol {
    var host: String {get}
    var path: String {get}
    var scheme: Scheme {get}
    var httpMethod: HttpMethod {get}
    var headers: [String: String] {get}
    var queryParams: [String: String] {get}
    var body: Data? {get}
    
    func buildRequest() throws -> URLRequest
}
