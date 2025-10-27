//
//  CoinChargeView.swift
//  Keychy
//
//  Created by rundo on 10/27/25.
//

import SwiftUI

struct CoinChargeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    
    var body: some View {
        VStack(spacing: 0) {
            Text("재화를 구매할 수 있다!")
        }
        .navigationTitle("재화 구매")
        .navigationBarTitleDisplayMode(.inline)
    }
}
