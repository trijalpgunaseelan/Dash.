//
//  SplashScreenView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/19/24.
//

import SwiftUI

struct SplashScreenView: View {
    let onSplashEnd: () -> Void
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.5)) {
                            logoScale = 1.0
                            logoOpacity = 1.0
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeInOut(duration: 1)) {
                                onSplashEnd()
                            }
                        }
                    }
            }
        }
    }
}
