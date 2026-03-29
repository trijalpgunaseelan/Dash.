//
//  GitHubAuthManager.swift
//  Dash
//
//  Created by Dhakshika on 3/29/26.
//

import AuthenticationServices
import CryptoKit
import Foundation
import Security
import UIKit

@MainActor
final class GitHubAuthManager: ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var user: GitHubUser?
    @Published private(set) var repositories: [Repository] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private enum OAuthConfig {
        static let clientID = "Ov23liSkzlTYDikZJmPc"
        static let redirectURI = "dash://github-callback"
        static let callbackScheme = "dash"
        static let scopes = ["read:user", "repo"]
    }

    private let keychain = KeychainHelper()
    private let tokenKey = "github_oauth_access_token"
    private var webAuthenticationSession: ASWebAuthenticationSession?

    func restoreSession() async {
        guard accessToken == nil else { return }

        guard let token = keychain.read(service: tokenKey, account: tokenKey), !token.isEmpty else {
            return
        }

        accessToken = token
        isAuthenticated = true

        do {
            try await fetchUserProfile()
            try await fetchRepositories()
            errorMessage = nil
        } catch {
            await logoutFromGitHub()
            errorMessage = "Saved session is no longer valid. Please sign in again."
        }
    }

    func signIn() async {
        errorMessage = nil
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            guard !OAuthConfig.clientID.isEmpty else {
                throw APIServiceError.oauthError(message: "Missing GitHub client ID configuration.")
            }

            let state = UUID().uuidString
            let codeVerifier = Self.generateCodeVerifier()
            let codeChallenge = Self.generateCodeChallenge(from: codeVerifier)
            let authorizationURL = try buildAuthorizationURL(state: state, codeChallenge: codeChallenge)
            print("GitHub OAuth URL: \(authorizationURL.absoluteString)")

            let callbackURL = try await startWebAuthentication(
                url: authorizationURL,
                callbackScheme: OAuthConfig.callbackScheme
            )

            let callbackItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []

            if let oauthError = callbackItems.first(where: { $0.name == "error" })?.value {
                throw APIServiceError.oauthError(message: oauthError)
            }

            guard let returnedState = callbackItems.first(where: { $0.name == "state" })?.value,
                  returnedState == state else {
                throw APIServiceError.oauthError(message: "OAuth state validation failed.")
            }

            guard let code = callbackItems.first(where: { $0.name == "code" })?.value,
                  !code.isEmpty else {
                throw APIServiceError.oauthError(message: "Authorization code was missing.")
            }

            let token = try await APIService.exchangeAuthorizationCodeForToken(
                code: code,
                codeVerifier: codeVerifier,
                redirectURI: OAuthConfig.redirectURI,
                clientID: OAuthConfig.clientID
            )

            let isSaved = keychain.save(service: tokenKey, account: tokenKey, value: token)
            guard isSaved else {
                throw APIServiceError.oauthError(message: "Failed to securely store access token.")
            }

            accessToken = token
            isAuthenticated = true

            try await fetchUserProfile()
            try await fetchRepositories()
            errorMessage = nil
        } catch {
            await logoutFromGitHub()
            errorMessage = error.localizedDescription
        }
    }

    func loadAuthenticatedDataIfNeeded() async {
        guard isAuthenticated else { return }
        if user != nil && !repositories.isEmpty { return }

        do {
            try await fetchUserProfile()
            try await fetchRepositories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logoutFromGitHub() async {
        _ = keychain.delete(service: tokenKey, account: tokenKey)
        webAuthenticationSession?.cancel()
        webAuthenticationSession = nil

        accessToken = nil
        isAuthenticated = false
        user = nil
        repositories = []
        errorMessage = nil
    }

    func logout() {
        _ = keychain.delete(service: tokenKey, account: tokenKey)
        webAuthenticationSession = nil

        accessToken = nil
        isAuthenticated = false
        user = nil
        repositories = []
    }

    private func fetchUserProfile() async throws {
        guard let token = accessToken else {
            throw APIServiceError.oauthError(message: "Missing access token.")
        }

        user = try await APIService.fetchAuthenticatedUser(accessToken: token)
    }

    private func fetchRepositories() async throws {
        guard let token = accessToken else {
            throw APIServiceError.oauthError(message: "Missing access token.")
        }

        repositories = try await APIService.fetchRepositories(accessToken: token)
    }

    private func buildAuthorizationURL(state: String, codeChallenge: String) throws -> URL {
        guard var components = URLComponents(string: "https://github.com/login/oauth/authorize") else {
            throw APIServiceError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "client_id", value: OAuthConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: OAuthConfig.redirectURI),
            URLQueryItem(name: "scope", value: OAuthConfig.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let url = components.url else {
            throw APIServiceError.invalidURL
        }

        return url
    }

    private func startWebAuthentication(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: APIServiceError.oauthError(message: "OAuth callback URL was missing."))
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = PresentationContextProvider.shared
            webAuthenticationSession = session

            if !session.start() {
                continuation.resume(throwing: APIServiceError.oauthError(message: "Unable to start authentication session."))
            }
        }
    }

    private static func generateCodeVerifier() -> String {
        let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        let length = 64
        var result = ""
        result.reserveCapacity(length)

        for _ in 0..<length {
            if let randomCharacter = charset.randomElement() {
                result.append(randomCharacter)
            }
        }

        return result
    }

    private static func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private final class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
    }
}

private struct KeychainHelper {
    func save(service: String, account: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    func delete(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
