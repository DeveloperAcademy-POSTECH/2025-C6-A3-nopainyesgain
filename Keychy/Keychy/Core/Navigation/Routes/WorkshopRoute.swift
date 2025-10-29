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

    // MARK: - 새로운 템플릿의 루트는 이렇게 추가해주면 됩니다. (예정)
    // case hkPreview
    // case hkCustomizing
    // case hkInfoInput
    // case hkComplete
}

