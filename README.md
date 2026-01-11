# AuthSampleApp
Demonstrates OAuth + PKCE in Swift

# Resources/ Learning Material
https://www.youtube.com/watch?v=996OiexHze0 (OAuth and OIDC)

https://www.youtube.com/watch?v=PfvSD6MmEmQ 

http://auth0.com/docs 

https://www.youtube.com/watch?v=vVM1Tpu9QB4 (ID va access tokens)

https://www.youtube.com/watch?v=5cQNwifDq1U (confidential vs public client

https://www.youtube.com/watch?v=h_1JAh3JPkI (PKCE)

https://medium.com/geekculture/implement-oauth2-pkce-in-swift-9bdb58873957 (swift PKCE blog , sample app)

https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authenticating-to-the-rest-api-with-an-oauth-app (github oauth flow)


# OAuth Flow in the Sample App

## Using Auth0 
- Docs https://auth0.com/docs/api
- Login and create your app
- Make sure callbackURl/ redirectURI includes you app's bundle ID if you are using as your callbackURLScheme. Read the medium article linked above for more details
- You need domain, cliendID, redirectURI from here that you will use in the authorize API call
- Refer docs to check API calls
- Sample app relies on ASWebAuthenticationSession to show the webview to get authorization from Auth0 during the flow
- PKCE is used since this is a public client, so we use the CommonCryto library to generate the code challenge and code verifier
- Basically, code verifier is the original string you create using a method that cryptograpically generates secure data
- Code challenge is just the SHA256 hash of the code verifier.
- Note that the hash function will always generate the exact same hash for a given string. But anyone who has the hash won't easily get the original string, at least it won't be worth the amount computation required to do this.
- Both code verifier and code challenge are generated for every request and never reused.
- The idea is that we make authorization call using code challenge and other necessary query params like client_id, redirect_uri, response_type, code challenge method etc
- This will give us the authorization code once user allows access
- Then we use the authorization code + code verifier and make the request to get access token

## Github
- Currently the app can only get the authorization code since github requires client secret to get access token and we do not want apps to hold onto client secret
- the rest of the flow to get authorization is very similar to Auth0

# Architecture

**OAuthService**
This is responsible for authorization and encapsulates the logic to show the webview to get user authorization. It use the ASWebAuthenticationSession to show the webview as needed.

**AuthServiceProtocol**
```
protocol AuthService {
    func authenticate() async throws -> String
}
```
Simple protocol to allow new services to adhere to and extend as needed

**Auth0Service**
- Conforms to AuthServiceProtocol
- Implements the authenticate function, creates authorization request to fetch authorization code and later access token request to get the token
- Relies on Auth0AuthorizeRequest and Auth0AccessTokenRequest for creating the requests to fetch the authorization code and access token

**GitAuthService**
- Conforms to AuthServiceProtocol
- Implements the authorization request in similar fashion as Auth0
- Note that the access token request does not work yet since github requires client secret.
- TODO: explore device auth flow to see if it could work

**NetworkService**
- Simple async network layer to fetch data for given RequestProtocol

**Parser**
- Simple parsing logic to parser data to appropriate struct
