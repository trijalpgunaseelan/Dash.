//
//  AuthenticationView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/24/24.
//

import SwiftUI
import LocalAuthentication

struct AuthenticationView: View {
    let onUnlock: () -> Void
    @State private var isUsingPasscode = false

    var body: some View {
        Group {
            if isUsingPasscode {
                PINLockView(onUnlock: onUnlock)
            } else {
                VStack {
                    Text("Authenticating...")
                        .font(.headline)
                        .foregroundColor(.purple)
                        .padding()

                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                }
                .onAppear(perform: authenticate)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to unlock Dash") { success, authError in
                DispatchQueue.main.async {
                    if success {
                        onUnlock()
                    } else {
                        isUsingPasscode = true
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                isUsingPasscode = true
            }
        }
    }
}
