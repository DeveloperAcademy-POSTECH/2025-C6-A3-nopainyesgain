//
//  SubmitCompleteAlert.swift
//  Keychy
//
//  Created by rundo on 11/25/25.
//

import SwiftUI

struct SubmitCompleteAlert: View {
    @Binding var isPresented: Bool
    let duration: TimeInterval = 2.0

    @State private var scale: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Image(.checkmarkAlert)

            Text("키링을 출품했어요!")
                .typography(.suit17B)
                .textOutline(color: .white100, width: 3)
                .foregroundStyle(.black100)

            Text("페스티벌 종료후 리워드가 지급돼요.")
                .typography(.suit17B)
                .textOutline(color: .white100, width: 3)
                .foregroundStyle(.black100)
                .padding(.top, 4)
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
