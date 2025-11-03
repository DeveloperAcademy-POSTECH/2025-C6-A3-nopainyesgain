//
//  WorkshopPreview.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI
import Lottie

struct WorkshopPreview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Environment(UserManager.self) private var userManager
    @State private var effectManager = EffectManager.shared

    let item: any WorkshopItem

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                itemPreview
                Spacer()
                itemInfo
            }
            .padding(.bottom, 120)

            actionButton
        }
        .padding(.horizontal, 35)
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Item Preview Section
extension WorkshopPreview {
    @ViewBuilder
    private var itemPreview: some View {
        ZStack {
            // 이미지 표시
            ItemDetailImage(itemURL: getPreviewURL())
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: getItemHeight())
                .opacity(isParticlePlaying ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: isParticlePlaying)

            // 파티클 이펙트일 경우 재생 뷰 표시
            if let particle = item as? Particle,
               let particleId = particle.id,
               effectManager.playingParticleId == particleId {
                particleLottieView(particleId: particleId, effectManager: effectManager)
                    .frame(height: getItemHeight())
            }

            // 이펙트일 경우 재생 버튼 표시
            if item is Sound || item is Particle {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        effectPlayButton
                    }
                }
                .padding(16)
            }
        }
    }

    /// 파티클이 재생 중인지 확인
    private var isParticlePlaying: Bool {
        if let particle = item as? Particle,
           let particleId = particle.id {
            return effectManager.playingParticleId == particleId
        }
        return false
    }

    /// 이펙트 재생 버튼
    private var effectPlayButton: some View {
        let itemId = item.id ?? ""
        let isDownloading = effectManager.downloadingItemIds.contains(itemId)
        let progress = effectManager.downloadProgress[itemId] ?? 0.0

        return Button {
            Task {
                if let sound = item as? Sound {
                    await effectManager.playSound(sound, userManager: userManager)
                } else if let particle = item as? Particle {
                    await effectManager.playParticle(particle, userManager: userManager)
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray50)
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white100, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)

                if isDownloading {
                    CircularProgressView(progress: progress)
                        .frame(width: 25, height: 25)
                } else {
                    Image(.polygon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
            }
        }
        .disabled(isDownloading)
    }

    /// 프리뷰 이미지 URL 가져오기
    private func getPreviewURL() -> String {
        if let template = item as? KeyringTemplate {
            return template.previewURL
        } else if let background = item as? Background {
            return background.backgroundImage
        } else if let carabiner = item as? Carabiner {
            return carabiner.carabinerImage[0]
        } else if let particle = item as? Particle {
            return particle.thumbnail
        } else if let sound = item as? Sound {
            return sound.thumbnail
        }
        return item.thumbnailURL
    }

    /// 아이템 타입에 따른 높이 계산
    private func getItemHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let imageWidth: CGFloat = 282
        let horizontalPadding: CGFloat = 70 // 35 * 2
        let availableWidth = screenWidth - horizontalPadding
        let scale = availableWidth / imageWidth

        if item is KeyringTemplate {
            // 키링: AcrylicPhotoPreView와 비슷한 비율
            return availableWidth * 1.3
        } else if item is Background {
            // 배경: 282x500 비율
            let ratio: CGFloat = 500 / 282
            return availableWidth * ratio
        } else {
            // 카라비너, 이펙트: 1:1 비율
            return availableWidth
        }
    }
}

// MARK: - Info Section
extension WorkshopPreview {
    private var itemInfo: some View {
        ItemDetailInfoSection(item: item)
    }
}

// MARK: - Action Button Section
extension WorkshopPreview {
    @ViewBuilder
    private var actionButton: some View {
        if item.isFree {
            freeButton
        } else {
            purchaseButton
        }
    }

    /// 무료 버튼 (비활성화)
    private var freeButton: some View {
        Button {
            // 무료 아이템 - 키링일 경우 만들기로 이동
            if let template = item as? KeyringTemplate,
               let templateId = template.id,
               let route = WorkshopRoute.from(string: templateId) {
                router.push(route)
            }
        } label: {
            Text("무료")
                .typography(.suit17B)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(.gray300)
        .disabled(!(item is KeyringTemplate))
    }

    /// 구입 버튼 (유료)
    private var purchaseButton: some View {
        Button {
            // 키링일 경우에만 만들기로 이동
            if let template = item as? KeyringTemplate,
               let templateId = template.id,
               let route = WorkshopRoute.from(string: templateId) {
                router.push(route)
            } else {
                // TODO: 구매 로직 구현
                print("구매: \(item.name) - \(item.workshopPrice) 코인")
            }
        } label: {
            HStack(spacing: 4) {
                Image(.keyCoin)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)

                Text("\(item.workshopPrice)")
                    .typography(.suit17B)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(.main500)
    }
}

#Preview {
    WorkshopPreview(
        router: NavigationRouter<WorkshopRoute>(),
        item: KeyringTemplate.acrylicPhoto
    )
    .environment(UserManager.shared)
}
