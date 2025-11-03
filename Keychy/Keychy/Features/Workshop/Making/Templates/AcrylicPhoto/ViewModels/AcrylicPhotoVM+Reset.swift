//
//  AcrylicPhotoVM+Reset.swift
//  Keychy
//
//  아크릴 포토 템플릿 뷰모델 초기화 메서드
//

import SwiftUI

extension AcrylicPhotoVM {
    // MARK: - 편집 데이터 초기화
    /// 편집뷰에서 뒤로가기 시 호출
    /// 누끼 제거된 이미지를 초기화
    func resetEditData() {
        removedBackgroundImage = UIImage()
        bodyImage = nil
    }
}
