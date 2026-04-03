//
//  GitHubAuthManager.swift
//  Dash
//
//  Created by Dhakshika on 3/29/26.
//

import AuthenticationServices
import Foundation
import Security
import UIKit
import UserNotifications

@MainActor
final class GitHubAuthManager: ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var user: GitHubUser?
    @Published private(set) var repositories: [Repository] = []
    @Published var notifications: [GitHubNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private enum OAuthConfig {
        static let clientID = "Ov23lijDapXSWmO4RsVv"
        static let clientSecret = "5202f89a433c7f4f546dd4273ab3e399d2e3a714"
        static let redirectURI = "dash://github-callback"
        static let callbackScheme = "dash"
        static let scopes = ["read:user", "repo", "notifications"]
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
            try await fetchNotifications()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load saved session."
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

            guard !OAuthConfig.clientSecret.isEmpty else {
                throw APIServiceError.oauthError(message: "Missing GitHub client secret configuration.")
            }

            let state = UUID().uuidString
            let authorizationURL = try buildAuthorizationURL(state: state)
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
                redirectURI: OAuthConfig.redirectURI,
                clientID: OAuthConfig.clientID,
                clientSecret: OAuthConfig.clientSecret
            )

            let isSaved = keychain.save(service: tokenKey, account: tokenKey, value: token)
            guard isSaved else {
                throw APIServiceError.oauthError(message: "Failed to securely store access token.")
            }

            accessToken = token
            isAuthenticated = true

            try await fetchUserProfile()
            try await fetchRepositories()
            try await fetchNotifications()
            errorMessage = nil
        } catch {
            await logoutFromGitHub()
            errorMessage = error.localizedDescription
        }
    }

    func loadAuthenticatedDataIfNeeded() async {
        guard isAuthenticated else { return }

        do {
            if user == nil {
                try await fetchUserProfile()
            }
            if repositories.isEmpty {
                try await fetchRepositories()
            }
            try await fetchNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchNotifications() async throws {
        guard let token = accessToken else {
            throw APIServiceError.oauthError(message: "Missing access token.")
        }

        let previousUnreadCount = notifications.filter { $0.unread }.count
        let fetchedNotifications = try await APIService.fetchNotifications(accessToken: token)
        notifications = fetchedNotifications

        let newUnreadCount = fetchedNotifications.filter { $0.unread }.count
        if newUnreadCount > previousUnreadCount {
            await sendLocalNotificationForNewGitHubActivity(newCount: newUnreadCount - previousUnreadCount)
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
        notifications = []
        errorMessage = nil
    }

    func logout() {
        _ = keychain.delete(service: tokenKey, account: tokenKey)
        webAuthenticationSession = nil

        accessToken = nil
        isAuthenticated = false
        user = nil
        repositories = []
        notifications = []
    }

    private func fetchUserProfile() async throws {
        guard let token = accessToken else {
            throw APIServiceError.oauthError(message: "Missing access token.")
        }

        user = try await APIService.fetchAuthenticatedUser(accessToken: token)
    }

    func fetchRepositories() async throws {
        guard let token = accessToken else {
            throw APIServiceError.oauthError(message: "Missing access token.")
        }

        repositories = try await APIService.fetchRepositories(accessToken: token)
    }

    private func buildAuthorizationURL(state: String) throws -> URL {
        guard var components = URLComponents(string: "https://github.com/login/oauth/authorize") else {
            throw APIServiceError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "client_id", value: OAuthConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: OAuthConfig.redirectURI),
            URLQueryItem(name: "scope", value: OAuthConfig.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state)
        ]

        guard let url = components.url else {
            throw APIServiceError.invalidURL
        }

        return url
    }

    private func startWebAuthentication(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in

                if let error = error as? ASWebAuthenticationSessionError,
                   error.code == .canceledLogin {
                    continuation.resume(throwing: APIServiceError.oauthError(message: "Login was cancelled."))
                    return
                }

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

            // FIX: Use ephemeral session to avoid device/account conflicts
            session.prefersEphemeralWebBrowserSession = true

            session.presentationContextProvider = PresentationContextProvider.shared
            webAuthenticationSession = session

            if !session.start() {
                continuation.resume(throwing: APIServiceError.oauthError(message: "Unable to start authentication session."))
            }
        }
    }

    private func sendLocalNotificationForNewGitHubActivity(newCount: Int) async {
        let center = UNUserNotificationCenter.current()

        do {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            }

            let content = UNMutableNotificationContent()
            content.title = "GitHub Updates"
            content.body = "You have \(newCount) new GitHub notification\(newCount == 1 ? "" : "s")."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )

            try await center.add(request)
        } catch {
        }
    }
}

private final class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }

        // FIX: Ensure a valid window is always returned
        return UIApplication.shared.windows.first ?? ASPresentationAnchor()
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
