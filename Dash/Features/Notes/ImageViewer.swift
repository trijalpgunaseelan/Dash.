//
//  ImageViewer.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/23/24.
//

import SwiftUI

struct ImageViewer: View {
    @Environment(\.presentationMode) var presentationMode
    var image: UIImage

    @State private var offset = CGSize.zero

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .offset(y: offset.height)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            self.offset = gesture.translation
                        }
                        .onEnded { _ in
                            if self.offset.height > 100 {
                                self.presentationMode.wrappedValue.dismiss()
                            } else {
                                self.offset = .zero
                            }
                        }
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
    }
}
