//
//  BundleSelectCarabinerView.swift
//  Keychy
//
//  Created by 김서현 on 10/28/25.
//

import SwiftUI

struct BundleSelectCarabinerView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    
    @State var viewModel: CollectionViewModel
    var body: some View {
        Text("카라비너 선택 화면입니다.")
        Text("선택한 배경화면 이름 : \(viewModel.selectedBackground.backgroundName)")
    }
}

#Preview {
    BundleSelectCarabinerView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
