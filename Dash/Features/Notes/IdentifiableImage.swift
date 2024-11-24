//
//  IdentifiableImage.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/23/24.
//

import UIKit

struct IdentifiableImage: Identifiable, Codable, Equatable {
    let id: UUID
    var image: UIImage

    init(image: UIImage) {
        self.id = UUID()
        self.image = image
    }

    enum CodingKeys: String, CodingKey {
        case id
        case imageData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        let imageData = try container.decode(Data.self, forKey: .imageData)
        self.image = UIImage(data: imageData) ?? UIImage()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        let imageData = image.jpegData(compressionQuality: 1.0)!
        try container.encode(imageData, forKey: .imageData)
    }

    static func ==(lhs: IdentifiableImage, rhs: IdentifiableImage) -> Bool {
        return lhs.id == rhs.id
    }
}
