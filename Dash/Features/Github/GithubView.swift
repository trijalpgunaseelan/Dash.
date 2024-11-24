//
//  GithubView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/20/24.
//

import SwiftUI

struct GitHubView: View {
    @State private var repositories: [Repository] = []
    @State private var isLoading = false
    private let githubUsername = "trijalgunaseelan"
    private let githubToken = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    @State private var didTapButton = false

    var body: some View {
        NavigationView {
            VStack {
                Text("GitHub Repos")
                    .font(.custom("Chewy-Regular", size: 28))
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                Spacer()

                if isLoading {
                    ProgressView("Loading repositories...")
                        .padding()
                } else if repositories.isEmpty {
                    Text("No repositories found.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(repositories) { repo in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(repo.name)
                                    .font(.headline)
                                if let description = repo.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()

                            Button(action: {
                                openRepositoryInGitHub(repo.htmlURL)
                            }) {
                                Image(systemName: "arrow.up.right.square.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }

                Spacer()

                Button(action: openGitHubApp) {
                    HStack {
                        Image("githubIconPurple")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .padding()
                    }
                    .padding()
                }
                .padding(.bottom, 16)
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .onAppear {
                if !didTapButton { fetchRepositories() }
                didTapButton = false
            }
        }
    }

    private func fetchRepositories() {
        isLoading = true
        guard let url = URL(string: "https://api.github.com/user/repos") else {
            print("Invalid URL")
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(githubToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("Error fetching repositories: \(error)")
                    return
                }
                guard let data = data else {
                    print("No data received")
                    return
                }
                do {
                    repositories = try JSONDecoder().decode([Repository].self, from: data)
                } catch {
                    print("Failed to decode repositories: \(error)")
                }
            }
        }
        task.resume()
    }

    private func openGitHubApp() {
        if let url = URL(string: "github://") {
            didTapButton = true
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func openRepositoryInGitHub(_ url: String) {
        if let repoURL = URL(string: url) {
            UIApplication.shared.open(repoURL, options: [:], completionHandler: nil)
        }
    }
}

struct Repository: Identifiable, Decodable {
    let id: Int
    let name: String
    let description: String?
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case htmlURL = "html_url"
    }
}
