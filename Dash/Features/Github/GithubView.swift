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
    @State private var sortOption: SortOption = .newest
    @State private var errorMessage: String?

    @State private var iconOffset: CGSize = .zero
    @GestureState private var dragOffset = CGSize.zero
    @State private var initialized = false

    private let githubToken = ""

    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case nameAscending = "Name A–Z"
        case nameDescending = "Name Z–A"
        case publicFirst = "Public"
        case privateFirst = "Private"

        var id: String { self.rawValue }
    }

    var sortedRepositories: [Repository] {
        switch sortOption {
        case .newest:
            return repositories.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .oldest:
            return repositories.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
        case .nameAscending:
            return repositories.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDescending:
            return repositories.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .publicFirst:
            return repositories.sorted { ($0.isPrivate ?? false) == false && ($1.isPrivate ?? false) == true }
        case .privateFirst:
            return repositories.sorted { ($0.isPrivate ?? false) == true && ($1.isPrivate ?? false) == false }
        }
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GitHub Repos")
                                .font(.system(size: 26, weight: .bold))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(SortOption.allCases) { option in
                                        Text(option.rawValue)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(sortOption == option ? Color.purple : Color(UIColor.systemGray5))
                                            )
                                            .foregroundColor(sortOption == option ? .white : .primary)
                                            .onTapGesture {
                                                sortOption = option
                                            }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 5)

                        if isLoading {
                            ProgressView("Loading repositories...")
                                .padding()
                            Spacer()
                        } else if let error = errorMessage {
                            Spacer()
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                        } else if sortedRepositories.isEmpty {
                            Spacer()
                            Text("No repositories found.")
                                .foregroundColor(.gray)
                            Spacer()
                        } else {
                            List {
                                ForEach(sortedRepositories) { repo in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(repo.name)
                                            .font(.headline)
                                            .lineLimit(1)

                                        if let desc = repo.description {
                                            Text(desc)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .lineLimit(2)
                                        }

                                        if let date = repo.createdAt {
                                            Text("Created: \(formattedDate(date))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Text(repo.isPrivate == true ? "Private" : "Public")
                                            .font(.caption2)
                                            .foregroundColor(repo.isPrivate == true ? .red : .green)

                                        Button {
                                            if let url = URL(string: repo.htmlURL) {
                                                UIApplication.shared.open(url)
                                            }
                                        } label: {
                                            HStack {
                                                Spacer()
                                                Label("Open in GitHub", systemImage: "arrow.up.right.square")
                                                    .font(.caption)
                                                    .foregroundColor(.purple)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                                    .listRowInsets(EdgeInsets())
                                    .padding(.vertical, 4)
                                    .listRowSeparator(.hidden)
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }

                    Image("githubIcon")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding()
                        .background(Circle().fill(Color.black).shadow(radius: 3))
                        .offset(x: iconOffset.width + dragOffset.width, y: iconOffset.height + dragOffset.height)
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation
                                }
                                .onEnded { value in
                                    iconOffset.width += value.translation.width
                                    iconOffset.height += value.translation.height
                                }
                        )
                        .onTapGesture {
                            openGitHubApp()
                        }
                        .onAppear {
                            if !initialized {
                                iconOffset = CGSize(
                                    width: geometry.size.width / 2 - 60,
                                    height: geometry.size.height / 2 - 60
                                )
                                initialized = true
                            }
                        }
                }
                .onAppear(perform: fetchRepositories)
            }
            .navigationBarHidden(true)
        }
    }

    private func openGitHubApp() {
        if let url = URL(string: "github://") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func fetchRepositories() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "https://api.github.com/user/repos?per_page=100") else {
            errorMessage = "Invalid GitHub URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(githubToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    repositories = try decoder.decode([Repository].self, from: data)
                } catch {
                    errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct Repository: Identifiable, Decodable {
    let id: Int
    let name: String
    let description: String?
    let htmlURL: String
    let createdAt: Date?
    let isPrivate: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case isPrivate = "private"
    }
}
