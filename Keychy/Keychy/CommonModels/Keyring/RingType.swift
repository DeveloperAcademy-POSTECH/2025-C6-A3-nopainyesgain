//
//  RingType.swift
//  KeytschPrototype
//
//  Created by Jini on 10/16/25.
//

import Foundation

enum RingType {
    case basic
    
    // MARK: - 링 이름
    var displayName: String {
        switch self {
        case .basic:
            return "기본 링"
        }
    }
    
    // MARK: - 링 크기
    var size: CGFloat {
        switch self {
        case .basic:
            return 90
        }
    }
    
    // MARK: - 다운로드 URL
    var imageURL: String {
        switch self {
        case .basic:
            return "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Rings%2FbasicRing.png?alt=media&token=f9b096c5-9b21-47be-8aad-98a24ccae386"
        }
    }
    
    // MARK: - Storage 경로
    var storagePath: String {
        switch self {
        case .basic:
            return "Rings/basicRing.png"
        }
    }

    // MARK: - ID로 타입 찾기
    static func fromID(_ id: String) -> RingType {
        switch id {
        case "yys7CtZoB3oB0fpoUurT":
            return .basic
        default:
            return .basic
        }
    }
}
