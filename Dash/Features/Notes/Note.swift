//
//  Note.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/23/24.
//

import SwiftUI
import Combine

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var imageDatas: [Data]?
    var createdAt: Date

    init(id: UUID = UUID(), title: String, content: String, images: [IdentifiableImage] = [], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.imageDatas = images.map { $0.image.jpegData(compressionQuality: 1.0)! }
        self.createdAt = createdAt
    }

    var images: [IdentifiableImage] {
        get {
            guard let imageDatas = imageDatas else { return [] }
            return imageDatas.compactMap { data in
                if let image = UIImage(data: data) {
                    return IdentifiableImage(image: image)
                }
                return nil
            }
        }
        set {
            imageDatas = newValue.map { $0.image.jpegData(compressionQuality: 1.0)! }
        }
    }
}
