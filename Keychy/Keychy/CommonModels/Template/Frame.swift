//
//  Frame.swift
//  Keychy
//
//  폴라로이드 프레임 모델
//

import Foundation
import FirebaseFirestore

struct Frame: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var frameURL: String
    var name: String
    var thumbnailURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case frameURL
        case name
        case thumbnailURL
    }
}
