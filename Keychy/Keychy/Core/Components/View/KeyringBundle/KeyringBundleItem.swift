//
//  KeyringBundleItem.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

// 뭉치 보관함 그리드에 들어가는 각각의 아이템 컴포넌트입니다
import SwiftUI

struct KeyringBundleItem: View {
    let bundle: KeyringBundle
    @State private var cachedImage: Image?

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .top) {
                // 캐시된 번들 이미지 표시
                bundleImageView
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                    )
                if bundle.isMain {
                    UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                        .fill(.pink100.opacity(0.7))
                        .overlay(
                            Text("대표")
                                .typography(.suit13M)
                                .foregroundStyle(.white100)
                        )
                        .frame(height: 26)
                        .frame(maxWidth: .infinity)
                    
                }
            }
            
            HStack {
                Text(bundle.name)
                    .typography(.suit15SB25)
                    .foregroundStyle(.black100)
                Spacer()
            }
            HStack {
                Text("걸린 키링")
                    .typography(.suit12M)
                    .foregroundStyle(.gray500)
                Spacer()
                Text("\(bundle.keyrings.count) / \(bundle.maxKeyrings) 개")
                    .typography(.suit12M)
                    .foregroundStyle(.main500)
            }
        }
        .onAppear {
            loadBundleImage()
        }
    }

    // MARK: - Bundle Image View

    private var bundleImageView: some View {
        return Group {
            if let cachedImage = cachedImage {
                cachedImage
                    .resizable()
                    .scaledToFit()
            } else {
                // 캐시 로딩 중 또는 실패 시 플레이스홀더
                Image(.ddochi)
                    .resizable()
                    .scaledToFit()
            }
        }
    }

    // MARK: - Load Bundle Image

    /// 캐시에서 번들 이미지 로드
    private func loadBundleImage() {
        guard let documentId = bundle.documentId else {
            print("⚠️ [BundleItem] documentId 없음")
            return
        }

        // 캐시에서 이미지 로드
        if let imageData = BundleImageCache.shared.load(for: documentId),
           let uiImage = UIImage(data: imageData) {
            cachedImage = Image(uiImage: uiImage)
//            print("✅ [BundleItem] 캐시 이미지 로드: \(bundle.name)")
        } else {
            print("⚠️ [BundleItem] 캐시 이미지 없음: \(bundle.name)")
        }
    }
}
