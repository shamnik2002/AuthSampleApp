//
//  AuthService.swift
//  AuthSampleApp
//
//  Created by Shamal nikam on 1/8/26.
//

import Foundation
import AuthenticationServices
import CommonCrypto
import CryptoKit

protocol AuthService {
    func authenticate() async throws -> String
}

enum AuthServiceError: Error {
    case codeChallengeGenerationError
    case authSessionError
    case authCodeMissing
    case invalidRequest
}

final class OAuthService: NSObject {
    
    struct Constants {
        static let responseTypeKey: String = "response_type"
        static let responseTypeValue: String = "code"
        static let codeChallengeKey: String = "code_challenge"
        static let codeChallengeMethodKey: String = "code_challenge_method"
        static let clientIDKey: String = "client_id"
        static let redirectURIKey: String = "redirect_uri"
    }
    
    var networkService: NetworkProtocol
    var parser: ParseProtocol
    init(networkService: NetworkProtocol, parser: ParseProtocol) {
        self.networkService = networkService
        self.parser = parser
    }
    
    func fetchAuthorizationCode(authorizeRequest: RequestProtocol, callbackURLScheme: String) async throws -> String {
                
        // generate the url for oauth session
        guard let url = try authorizeRequest.buildRequest().url else {
            throw NetworkError.invalidURL
        }
        
        do {
            // 4. get the auth code
            let authorizationCode: String = try await withCheckedThrowingContinuation {[weak self] continuation in
                let authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { url, error in
                    
                    guard error == nil, let url = url else {
                        continuation.resume(throwing: AuthServiceError.authSessionError)
                        return
                    }
                    
                    guard let authorizationCode = url.getQueryStringParameter(Constants.responseTypeValue) else {
                        continuation.resume(throwing: AuthServiceError.authCodeMissing)
                        return
                    }
                    
                    continuation.resume(returning: authorizationCode)
                }
                authSession.presentationContextProvider = self
                authSession.start()
            }
            return authorizationCode
        }catch {
            // log error
            throw error
        }
    }
    
    func generateCodeVerifier() -> String {
        // define a buffer with specific length
        var buffer = [UInt8](repeating: 0, count: 32)
        // create cyrptograpically secure random bytes
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        
        // convert bytes to string, replace +, /, = since they are not allowed PKCE verifier per RFC 7636
        return Data(buffer)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
    
    func generateCodeChallenge(verifier: String) throws -> String {
        guard let data = verifier.data(using: .utf8) else {
            throw AuthServiceError.codeChallengeGenerationError
        }

        var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes {
            CC_SHA256($0.baseAddress, CC_LONG(data.count), &buffer)
        }
        let hash = Data(buffer)
        return hash.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
    
}

extension OAuthService: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession)
       -> ASPresentationAnchor {
           
           return keyWindow() ?? ASPresentationAnchor()
       }
    
    func keyWindow() -> UIWindow? {
        return UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: { $0.isKeyWindow })
    }
}

fileprivate extension URL {
    func getQueryStringParameter(_ parameter: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == parameter })?.value
    }
}

