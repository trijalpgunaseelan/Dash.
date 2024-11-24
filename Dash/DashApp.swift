//
//  DashApp.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/19/24.
//

import SwiftUI
import LocalAuthentication

@main
struct DashApp: App {
    @State private var isSplashScreenActive = true
    @State private var isLocked = true

    var body: some Scene {
        WindowGroup {
            if isSplashScreenActive {
                SplashScreenView(onSplashEnd: {
                    isSplashScreenActive = false
                })
            } else if isLocked {
                AuthenticationView(onUnlock: {
                    isLocked = false
                })
            } else {
                MainTabView()
            }
        }
    }
}
