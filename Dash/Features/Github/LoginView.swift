//
//  LoginView.swift
//  Dash
//
//  Created by Dhakshika on 3/29/26.
//  Edited by Dhakshika on 2/4/26


import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager: GitHubAuthManager

    var body: some View {
        VStack(spacing: 20) {
            Image("githubIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("Sign in to GitHub")
                .font(.title3.bold())

            Text("Connect your account to load your profile and repositories.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Swift.Task {
                    await authManager.signIn()
                }
            } label: {
                HStack(spacing: 8) {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(authManager.isLoading ? "Signing In..." : "Login with GitHub")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.black)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(authManager.isLoading)

            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
