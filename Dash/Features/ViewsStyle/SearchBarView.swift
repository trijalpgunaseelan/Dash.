//
//  SearchBarView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 12/1/24.
//

import SwiftUICore
import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            TextField("Search...", text: $searchText)
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
        }
    }
}
