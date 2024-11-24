//
//  ContentView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/19/24.
//

import SwiftUI

struct ContentView: View {
    @State private var currentScreen: Screen = .splash

    enum Screen {
        case splash, pinLock, mainTab
    }

    var body: some View {
        ZStack {
            switch currentScreen {
            case .splash:
                SplashScreenView(onSplashEnd: {
                    withAnimation(.easeInOut(duration: 1)) {
                        currentScreen = .pinLock
                    }
                })
                .transition(.move(edge: .trailing))
            case .pinLock:
                PINLockView(onUnlock: {
                    withAnimation(.easeInOut(duration: 1)) {
                        currentScreen = .mainTab
                    }
                })
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            case .mainTab:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
