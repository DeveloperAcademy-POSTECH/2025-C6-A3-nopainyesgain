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
    // 기본값 - 수정 필
    var maxKeyringCount: Int = 100
    var coin: Int = 0
    var copyVoucher: Int = 0
}
