//
//  WorkshopRoute.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//
import UIKit

/// 공방 탭 라우팅
enum WorkshopRoute: Hashable {
    // MARK: - 아크릴 포토 템플릿
    case acrylicPhotoPreview
    case acrylicPhotoCrop
    case acrylicPhotoEdited
    case acrylicPhotoCustomizing
    case acrylicPhotoInfoInput
    case acrylicPhotoComplete
    case coinCharge
    case myItems
    
    // MARK: - 텍스트 포토 템플릿
    case TextPhotoPreView
    
    // MARK: - 새로운 템플릿의 루트는 이렇게 추가해주면 됩니다. (예정)
    // case hkPreview
    // case hkCustomizing
    // case hkInfoInput
    // case hkComplete
    
    /// template.id 문자열을 WorkshopRoute로 변환
    static func from(string: String) -> WorkshopRoute? {
        switch string {
        case "AcrylicPhoto":
            return .acrylicPhotoPreview
        case "CirclePhoto":
            return .acrylicPhotoPreview
        case "CloudDream":
            return .acrylicPhotoPreview
        case "FlowerGarden":
            return .acrylicPhotoPreview
        case "Heartkeyring":
            return .acrylicPhotoPreview
        case "MessageCard":
            return .acrylicPhotoPreview
        case "MinimalSquare":
            return .acrylicPhotoPreview
        case "NeonSign":
            return .acrylicPhotoPreview
        case "PolaroidStyle":
            return .acrylicPhotoPreview
        case "RainbowDoodle":
            return .acrylicPhotoPreview
        case "SimpleText":
            return .acrylicPhotoPreview
        case "Starkeyring":
            return .acrylicPhotoPreview
        case "VintageFilm":
            return .TextPhotoPreView
            // 필요한 프리뷰 케이스들 추가
        default:
            return nil
        }
    }
}

