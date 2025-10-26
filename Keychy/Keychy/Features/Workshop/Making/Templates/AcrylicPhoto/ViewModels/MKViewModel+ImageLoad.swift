//
//  MKViewModel+ImageLoad.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/16/25.
//

import SwiftUI
import PhotosUI

// MARK: - 이미지 로드
extension MKViewModel {

    /// 이미지 로드 - PhotosPicker
    /// - PhotosPickerItem은 **실제 이미지 데이터가 아니라 참조(reference)**.
    /// - 그래서 실제 이미지를 가져오려면 반드시 로딩 과정이 필요함.
    /// 1. 메모리 효율: 사진을 선택했다고 바로 메모리에 올리면 큰 이미지의 경우 앱이 느려짐
    /// 2. 권한 관리: 사용자가 선택한 사진만 접근 가능
    /// 3. 비동기 처리: 큰 이미지는 로딩 시간이 필요하므로 UI를 멈추지 않기 위해
    func loadImage(from item: PhotosPickerItem) {
        isProcessing = true
        errorMessage = nil

        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                self.isProcessing = false

                switch result {
                case .success(let data):
                    guard let data,
                          let uiImage = UIImage(data: data) else {
                        self.errorMessage = "이미지를 불러올 수 없습니다."
                        return
                    }

                    self.selectedImage = uiImage

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.resetToCenter()
                    }

                case .failure(let error):
                    self.errorMessage = "이미지 로드 실패: \(error.localizedDescription)"
                }
            }
        }
    }
}
