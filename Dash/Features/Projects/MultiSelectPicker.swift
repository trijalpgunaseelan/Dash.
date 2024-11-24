//
//  MultiSelectPicker.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/23/24.
//

import SwiftUI

struct MultiSelectPicker: View {
    @Binding var selections: [String]
    let options: [String]
    let title: String

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    if selections.contains(option) {
                        selections.removeAll { $0 == option }
                    } else {
                        selections.append(option)
                    }
                }) {
                    HStack {
                        Text(option)
                        if selections.contains(option) {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                Text(selections.joined(separator: ", "))
                    .foregroundColor(.gray)
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
}
