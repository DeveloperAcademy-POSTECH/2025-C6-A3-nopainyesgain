//
//  SplashView.swift
//  Keychy
//
//  Created by Jini on 10/27/25.
//

import SwiftUI

// 스플래쉬 뷰
struct SplashView: View {
    var body: some View {
        
        ZStack() {
            VStack(spacing: 20) {
                Image("appIcon")
                    .resizable()
                    .frame(width: 100, height: 100)
                
                Image("logoType")
                    .resizable()
                    .frame(width: 98, height: 20)
            }
        }
    }
}

#Preview {
    SplashView()
}
