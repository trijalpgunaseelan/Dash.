//
//  PINLockView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/19/24.
//

import SwiftUI

struct PINLockView: View {
    @State private var pin: String = ""
    @FocusState private var isFocused: Bool
    @State private var isAnimating = false
    let onUnlock: () -> Void

    var body: some View {
        VStack {
            Spacer()

            Text("Enter PIN")
                .font(.custom("HeeboBoldFont", size: 40))
                .italic()
                .foregroundColor(.purple)
                .padding(.bottom, 20)

            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .stroke(pin.count > index ? Color.purple : Color.gray, lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .fill(pin.count > index ? Color.purple : Color.clear)
                                .frame(width: 20, height: 20)
                        )
                }
            }
            .padding()

            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)  
                .onChange(of: pin) { newValue in
                    if pin.count > 6 {
                        pin = String(pin.prefix(6))
                    } else if pin.count == 6 {
                        verifyPin()
                    }
                }
                .frame(width: 0, height: 0)
                .opacity(0)

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .scaleEffect(isAnimating ? 1.2 : 1.0) 
        .animation(.spring(), value: isAnimating)
    }

    private func verifyPin() {
        let correctPIN = "252525"

        if pin == correctPIN {
            isAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onUnlock()
            }
        } else {
            pin = ""
        }
    }
}
