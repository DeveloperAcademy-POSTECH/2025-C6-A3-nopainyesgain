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
