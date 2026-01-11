//
//  GitAuthService.swift
//  AuthSampleApp
//
//  Created by Shamal nikam on 1/11/26.
//

/*
 NOTE: Github currently doesn't allow getting access token using PKCE. So we need to store client secret
 which means in case of Git you need a backend server that can safely access client secret and make the call to get the access token
 */


import Foundation

final class GitAuthService: AuthService {
    
    struct Constants {
        static let authDomain = "github.com/login/oauth"
        static let clientID = "Ov23liMIH9pkqdXzECuG"
        static let bundleID = Bundle.main.bundleIdentifier ?? "" // find a better way to do this
        static var redirectURI: String  {
            "\(bundleID)://github.com/shamnik2002/callback"
        }
    }
    let oauthService: OAuthService
    let networkService: NetworkProtocol
    let parser: ParseProtocol
    
    init(networkService: NetworkProtocol, parser: ParseProtocol) {
        
        self.networkService = networkService
        self.parser = parser
        oauthService = OAuthService(networkService: networkService, parser: parser)
    }
    
    func authenticate() async throws -> String {
        
        // Follow PKCE
        // code verifier and challenge are generate for each request to avoid anyone stealing and using them
        // 1. Create the code verifier
        let codeVerifier = oauthService.generateCodeVerifier()
        // 2. generate code challenge from the code verifier
        let codeChallenge = try oauthService.generateCodeChallenge(verifier: codeVerifier)
        let authorizeRequest = GitAuthorizeRequest(responseType: OAuthService.Constants.responseTypeValue,
                                                   codeChallenge: codeChallenge,
                                                   codeChallengeMethod: "S256",
                                                   clientID: Constants.clientID,
                                                   redirectURI: Constants.redirectURI)
        // 3. Use ASWebAuthenticationSession to direct user to the login page
        let authorizationCode = try await oauthService.fetchAuthorizationCode(authorizeRequest: authorizeRequest, callbackURLScheme: Constants.bundleID)
        
        do {
            // 5. use the auth code + code verifier to get the access token
            // create access token request
            let request = GitAccessTokenRequest(authCode: authorizationCode, codeVerifier: codeVerifier)
            let data = try await self.networkService.fetchData(request: request)
            let response = try self.parser.parse(data: data, type: Auth0Response.self)
            return response.access_token
        }catch {
            throw error
        }
    }
}

// Not in use
struct GitAccessTokenRequest: RequestProtocol {
    var queryParams: [String : String] = [:]
    
    var host: String = "github.com"
    
    var path: String = "/login/oauth/access_token"
    
    var scheme: Scheme = .https
    
    var httpMethod: HttpMethod = .POST
    
    var headers: [String : String] = [:]
    
    var bodyParams: [String : String]
    
    var body: Data?
    
    init(authCode: String, codeVerifier: String) {
        
        bodyParams = [
            "client_id": Auth0Service.Constants.clientID,
            "code_verifier": codeVerifier,
            "code": authCode,
            "redirect_uri": Auth0Service.Constants.redirectURI
        ]
    }
    
    func buildRequest() throws -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme.rawValue
        urlComponents.host = host
        urlComponents.path = path
        
        guard let url = urlComponents.url else {
            throw AuthServiceError.invalidRequest
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type") // Indicate the body content is JSON

        var urlComponentsBody = URLComponents()
        urlComponentsBody.queryItems = bodyParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        let postData = urlComponentsBody.query?.data(using: .utf8)
        urlRequest.httpMethod = httpMethod.rawValue
        
        urlRequest.httpBody = postData
        return urlRequest
    }
    
    
}

struct GitAuthResponse: Codable {
    let access_token: String
    let refresh_token: String?
    let id_token: String?
    let token_type: String
    let expires_in: Int
}


struct GitAuthorizeRequest: RequestProtocol {
    var host: String = "github.com"
    
    var path: String = "/login/oauth/authorize"
    
    var scheme: Scheme = .https
    
    var httpMethod: HttpMethod = .GET
    
    var headers: [String : String] = [:]
    
    var queryParams: [String : String]
    
    var body: Data?
    
    init(responseType: String, codeChallenge: String, codeChallengeMethod: String, clientID: String, redirectURI: String) {
        queryParams = [
            OAuthService.Constants.responseTypeKey: OAuthService.Constants.responseTypeValue,
            OAuthService.Constants.codeChallengeKey: codeChallenge,
            OAuthService.Constants.codeChallengeMethodKey: codeChallengeMethod,
            OAuthService.Constants.clientIDKey: clientID,
            OAuthService.Constants.redirectURIKey: redirectURI
        ]
    }

    func buildRequest() throws -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme.rawValue
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = urlComponents.url else {
            throw AuthServiceError.invalidRequest
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        return urlRequest
    }
}
