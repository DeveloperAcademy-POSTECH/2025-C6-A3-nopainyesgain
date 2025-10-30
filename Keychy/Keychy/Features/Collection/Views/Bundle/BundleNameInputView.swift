//
//  BundleNameInputView.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SwiftUI

struct BundleNameInputView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    BundleNameInputView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
