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
                Image("introIcon")
                Image("introTypo")
            }
        }
    }
}

#Preview {
    SplashView()
}
