//
//  PreviewGuiding.swift
//  Keychy
//
//  Created by 길지훈 on 10/29/25.
//  범용 템플릿 가이드 뷰 (모든 템플릿에서 사용 가능)
//

// MARK: - 프리뷰 가이딩 추상화하다가 템플릿마다 많이 다를 것 같아서 캔슬함
// MARK: - 하지만 사진첩으로 연결 이런 기능이 필요없는 뷰라면 충분히 이걸로 사용해도 될듯.

import SwiftUI
import NukeUI

struct PreviewGuiding: View {
    @Environment(\.dismiss) var dismiss
    let guidingText: String
    let guidingImageURL: String
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 상단 닫기 버튼
            HStack {
                backBtn
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)

            guidingIcon
                .padding(.bottom, 8)

            guidingTextLabel
                .padding(.bottom, 22)

            guidingImage
                .padding(.bottom, 23)

            // 확인 버튼
            confirmBtn
                .padding(.horizontal, 20)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Components
extension PreviewGuiding {
    private var backBtn: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 24))
                .foregroundStyle(.primary)
        }
    }

    private var confirmBtn: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onConfirm()
            }
        } label: {
            Text("확인")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var guidingIcon: some View {
        Image(.fireworks)
            .resizable()
            .frame(width: 32, height: 32)
    }

    private var guidingTextLabel: some View {
        Text(guidingText)
            .typography(.suit20B)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var guidingImage: some View {
        LazyImage(url: URL(string: guidingImageURL)) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
            } else if state.isLoading {
                ProgressView()
            } else {
                Color.gray.opacity(0.1)
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

