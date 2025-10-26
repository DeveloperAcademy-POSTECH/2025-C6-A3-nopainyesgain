//
//  BundleCreateView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//

import SwiftUI

struct BundleCreateView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    
    @State var viewModel: CollectionViewModel
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    BundleCreateView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
