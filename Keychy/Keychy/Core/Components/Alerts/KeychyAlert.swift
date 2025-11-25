//
//  KeychyAlert.swift
//  Keychy
//
//  Created by 길지훈 on 11/15/25.
//

import SwiftUI

enum AlertType {
    case checkmark           // 체크마크 (구매완료랑 뭐 누끼따기 이런데서 다양하기 쓰더군.)
    case copy               // 키링 복사
    case imageSave          // 이미지 저장
    case linkCopy           // 링크 복사
    case unpack             // 선물 포장 해제
    case addToCollection    // 보관함에 키링 추가
    case fail               // 무언가 실패함 (땀흘리는 아이콘임)
    case vote

    var imageName: String {
        switch self {
        case .checkmark: return "checkmarkAlert"
        case .copy: return "copyKeyringAlert"
        case .imageSave: return "saveImageAlert"
        case .linkCopy: return "copyLinkAlert"
        case .unpack: return "openPresentAlert"
        case .addToCollection: return "receivePresentAlert"
        case .fail: return "failAlert"
        case .vote: return "voteCompleteImage"
        }
    }
}

struct KeychyAlert: View {
    let type: AlertType
    let message: String
    @Binding var isPresented: Bool
    let duration: TimeInterval = 2.0

    @State private var scale: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Image(type.imageName)

            Text(message)
                .typography(.suit17SB)
                .textOutline(color: .white100, width: 3)
                .foregroundStyle(.black100)
        }
        .onChange(of: isPresented) { oldValue, newValue in
            if newValue {
                playAnimation()
            }
        }
        .onAppear {
            if isPresented {
                playAnimation()
            }
        }
        .scaleEffect(scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private func playAnimation() {
        // 1. 등장 애니메이션
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.0
        }

        // 2. duration 만큼 대기 후 소멸
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 0
            }

            // 3. 소멸 애니메이션 끝난 후 isPresented를 false로
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPresented = false
            }
        }
    }
}
