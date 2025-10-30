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
            return 100
        }
    }
    
    // MARK: - 다운로드 URL
    var imageURL: String {
        switch self {
        case .basic:
            return "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Rings%2FbasicRing.png?alt=media&token=73c8ac59-544a-45f8-a1d6-119d034c716e"
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
