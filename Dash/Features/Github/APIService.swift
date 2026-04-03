//
//  APIService.swift
//  Dash
//
//  Created by Dhakshika on 3/29/26.
//

import Foundation

enum APIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case oauthError(message: String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid server response."
        case .serverError(let statusCode):
            return "Server returned status code \(statusCode)."
        case .oauthError(let message):
            return message
        case .decodingError:
            return "Failed to decode response."
        }
    }
}

struct GitHubUser: Decodable {
    let id: Int
    let login: String
    let name: String?
    let avatarURL: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case name
        case avatarURL = "avatar_url"
        case bio
    }
}

struct Repository: Identifiable, Decodable {
    let id: Int
    let name: String
    let description: String?
    let htmlURL: String
    let createdAt: Date?
    let isPrivate: Bool?
    let stargazersCount: Int?
    let forksCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case isPrivate = "private"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
    }
}

struct GitHubNotification: Identifiable, Decodable {
    let id = UUID()
    let reason: String
    let unread: Bool
    let updatedAt: String
    let subject: Subject

    struct Subject: Decodable {
        let title: String
        let url: String?
        let type: String
    }

    var deduplicationKey: String {
        "\(reason)|\(updatedAt)|\(subject.title)|\(subject.type)"
    }

    enum CodingKeys: String, CodingKey {
        case reason
        case unread
        case updatedAt = "updated_at"
        case subject
    }
}

struct APIService {

    private struct OAuthTokenResponse: Decodable {
        let accessToken: String?
        let scope: String?
        let tokenType: String?
        let error: String?
        let errorDescription: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case scope
            case tokenType = "token_type"
            case error
            case errorDescription = "error_description"
        }
    }

    static func exchangeAuthorizationCodeForToken(
        code: String,
        redirectURI: String,
        clientID: String,
        clientSecret: String
    ) async throws -> String {

        guard let url = URL(string: "https://github.com/login/oauth/access_token") else {
            throw APIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "client_id=\(percentEncode(clientID))&client_secret=\(percentEncode(clientSecret))&code=\(percentEncode(code))&redirect_uri=\(percentEncode(redirectURI))"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)

        if let error = tokenResponse.error {
            let message = tokenResponse.errorDescription ?? error
            throw APIServiceError.oauthError(message: message)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIServiceError.serverError(statusCode: httpResponse.statusCode)
        }

        guard let accessToken = tokenResponse.accessToken, !accessToken.isEmpty else {
            throw APIServiceError.decodingError
        }

        return accessToken
    }

    static func fetchAuthenticatedUser(accessToken: String) async throws -> GitHubUser {

        guard let url = URL(string: "https://api.github.com/user") else {
            throw APIServiceError.invalidURL
        }

        let request = makeAuthenticatedRequest(url: url, accessToken: accessToken)

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateHTTPResponse(response)

        return try JSONDecoder().decode(GitHubUser.self, from: data)
    }

    static func fetchRepositories(accessToken: String) async throws -> [Repository] {

        guard let url = URL(string: "https://api.github.com/user/repos?per_page=100") else {
            throw APIServiceError.invalidURL
        }

        let request = makeAuthenticatedRequest(url: url, accessToken: accessToken)

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateHTTPResponse(response)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([Repository].self, from: data)
    }

    static func fetchNotifications(accessToken: String) async throws -> [GitHubNotification] {

        guard let url = URL(string: "https://api.github.com/notifications") else {
            throw APIServiceError.invalidURL
        }

        let request = makeAuthenticatedRequest(url: url, accessToken: accessToken)

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateHTTPResponse(response)

        return try JSONDecoder().decode([GitHubNotification].self, from: data)
    }

    private static func makeAuthenticatedRequest(url: URL, accessToken: String) -> URLRequest {

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Dash-iOS", forHTTPHeaderField: "User-Agent")

        return request
    }

    private static func validateHTTPResponse(_ response: URLResponse) throws {

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIServiceError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    private static func percentEncode(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
