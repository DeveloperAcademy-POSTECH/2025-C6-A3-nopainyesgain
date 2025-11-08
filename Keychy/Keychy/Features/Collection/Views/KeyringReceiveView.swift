//
//  KeyringReceiveView.swift
//  Keychy
//
//  Created by Jini on 11/8/25.
//

import SwiftUI

struct KeyringReceiveView: View {
    let name: String
    
    var body: some View {
        VStack(spacing: 10) {
            headerSection
            
            messageSection
            
            keyringImage
            
            Spacer()
            
            receiveButton
        }
    }
}

// 헤더 (버튼 + 수신 정보)
extension KeyringReceiveView {
    private var headerSection: some View {
        HStack {
            CircleGlassButton(
                imageName: "dismiss",
                action: {}
            )
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private var messageSection: some View {
        VStack(spacing: 10) {
            Text("[\(name)]가 키링을 선물했어요!")
                .typography(.suit20B)
                .foregroundColor(.black100)
            
            Text("수락하시겠어요?")
                .typography(.suit16M)
                .foregroundColor(.black100)
                .padding(.bottom, 30)
        }
    }
}

// 수신된 키링 이미지
extension KeyringReceiveView {
    private var keyringImage: some View {
        Rectangle()
            .fill(.gray300)
            .frame(width: 304, height: 490)
    }
}

// 하단 버튼
extension KeyringReceiveView {
    private var receiveButton: some View {
        Button {
            // action
        } label: {
            Text("수락하기")
                .typography(.suit17B)
                .padding(.vertical, 7.5)
                .foregroundStyle(.white100)

        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 1000)
                .fill(.black80)
                .frame(maxWidth: .infinity)
        )
        .padding(.horizontal, 34)
    }
}

#Preview {
    KeyringReceiveView(name: "싱싱이")
}
