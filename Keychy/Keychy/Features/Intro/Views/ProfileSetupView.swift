//
//  ProfileSetupView.swift
//  Keychy
//
//  Created by Jini on 10/28/25.
//

import SwiftUI

// 첫 실행 시 닉네임 등 설정 뷰
struct ProfileSetupView: View {
    @Bindable var viewModel: IntroViewModel
    
    @State private var nickname: String = ""
    
    var body: some View {
        VStack {
            Text("ProfileSetupView")
            
            TextField("닉네임을 입력하세요", text: $nickname)
                .textFieldStyle(.plain)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )

            Button(action: {
                viewModel.saveProfile(nickname: nickname)
            }) {
                Text("다음")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pink)
                    )
            }
            //.disabled(!isValidNickname)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        

        
    }
}
