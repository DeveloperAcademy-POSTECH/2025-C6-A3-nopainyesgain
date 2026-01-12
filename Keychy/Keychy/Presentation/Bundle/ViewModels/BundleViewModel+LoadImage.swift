//
//  BundleViewModel+LoadImage.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//

import NukeUI
import SwiftUI

// MARK: - Nuke를 통해 캐싱된 이미지, 또는 URL을 통해 이미지를 로드하는 메서드들
extension BundleViewModel {
    /// 뒷 카라비너 이미지 (또는 단일 카라비너 이미지)
    func backCarabinerImage(carabiner: Carabiner) -> some View {
        LazyImage(url: URL(string: carabiner.backImageURL)) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
            } else if state.isLoading {
                ProgressView()
            } else {
                Color.clear
            }
        }
    }
    
    /// 앞 카라비너 이미지 (햄버거 타입만)
    func frontCarabinerImage(carabiner: Carabiner) -> some View {
        Group {
            if let frontURL = carabiner.frontImageURL {
                LazyImage(url: URL(string: frontURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if state.isLoading {
                        ProgressView()
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
    }
    
    /// 배경 이미지 뷰
    var backgroundImage: some View {
        Group {
            if let bundle = selectedBundle,
               let bg = resolveBackground(from: bundle.selectedBackground) {
                LazyImage(url: URL(string: bg.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if state.isLoading {
                        Color.clear
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
    }
}
