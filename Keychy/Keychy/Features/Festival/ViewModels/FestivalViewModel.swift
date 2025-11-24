//
//  FestivalViewModel.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import SwiftUI

@Observable
class FestivalViewModel {

    // MARK: - Properties

    var isLoading = false
    var isUploading = false

    // 페스티벌에서 사용하는 유저 정보 관련
    var maxKeyringCount: Int = 100 // 기본값
    var coin: Int = 0
    var copyVoucher: Int = 0
    
    // MARK: - Upload Sample Data

    /// ShowcaseFestivalKeyring 컬렉션에 샘플 데이터 업로드
    func uploadSampleData() async {
        guard !isUploading else { return }

        await MainActor.run {
            isUploading = true
        }

        await uploadSampleFestivalKeyrings()

        await MainActor.run {
            isUploading = false
        }
    }
}
