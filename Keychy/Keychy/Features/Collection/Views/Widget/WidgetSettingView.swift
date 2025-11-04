//
//  WidgetSettingView.swift
//  Keychy
//
//  Created by Jini on 10/30/25.
//

import SwiftUI

struct WidgetSettingView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    
    var body: some View {
        VStack {
            Text("준비 중")
        }
        .navigationTitle("위젯 설정")
        .toolbar(.hidden, for: .tabBar)
        
    }
}

