//
//  Auth0Service.swift
//  AuthSampleApp
//
//  Created by Shamal nikam on 1/11/26.
//
import Foundation

final class Auth0Service: AuthService {
    
    struct Constants {
        static let authDomain = "dev-s33skbl75qs3ya13.us.auth0.com"
        static let clientID = "mNm4kW9byNqRMaxXQJAjkv3zPtJ6vL5e"
        static let bundleID = Bundle.main.bundleIdentifier ?? "" // find a better way to do this
        static var redirectURI: String  {
            "\(Constants.bundleID)://\(Constants.authDomain)/ios/\(Constants.bundleID)/callback"
        }
    }
    let oauthService: OAuthService
    let networkService: NetworkProtocol
    let parser: ParseProtocol
    
    var redirectURI: String  {
        "\(Constants.bundleID)://\(Constants.authDomain)/ios/\(Constants.bundleID)/callback"
    }
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
        // 3. Use ASWebAuthenticationSession to direct user to the login page
        let authorizeRequest = Auth0AuthorizeRequest(responseType: OAuthService.Constants.responseTypeValue,
                                                     codeChallenge: codeChallenge,
                                                     codeChallengeMethod: "S256",
                                                     clientID: Constants.clientID,
                                                     redirectURI: Constants.redirectURI)
        let authorizationCode = try await oauthService.fetchAuthorizationCode(authorizeRequest: authorizeRequest, callbackURLScheme: Constants.bundleID)
        
        do {
            // 5. use the auth code + code verifier to get the access token
            // create access token request
            let request = Auth0AccessTokenRequest(authCode: authorizationCode, codeVerifier: codeVerifier)
            let data = try await self.networkService.fetchData(request: request)
            let response = try self.parser.parse(data: data, type: Auth0Response.self)
            return response.access_token
        }catch {
            throw error
        }
    }
}

struct Auth0AccessTokenRequest: RequestProtocol {
    var queryParams: [String : String] = [:]
    
    var host: String = Auth0Service.Constants.authDomain
    
    var path: String = "/oauth/token"
    
    var scheme: Scheme = .https
    
    var httpMethod: HttpMethod = .POST
    
    var headers: [String : String] = [:]//["content-type": "application/json"]
    
    var bodyParams: [String : String]
    
    var body: Data?
    
    init(authCode: String, codeVerifier: String) {
        
        bodyParams = [
            "grant_type": "authorization_code",
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

struct Auth0AuthorizeRequest: RequestProtocol {
    var host: String = Auth0Service.Constants.authDomain
    
    var path: String = "/authorize"
    
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

struct Auth0Response: Codable {
    let access_token: String
    let refresh_token: String?
    let id_token: String?
    let token_type: String
    let expires_in: Int
}
