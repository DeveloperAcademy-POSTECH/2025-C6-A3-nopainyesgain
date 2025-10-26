//
//  BundleDetailView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//
// 키링 뭉치 상세보기 화면
import SwiftUI

struct BundleDetailView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    
    var body: some View {
        Text("뭉치 상세보기 화면입니다")
    }
}

#Preview {
    BundleDetailView(router: NavigationRouter())
}
