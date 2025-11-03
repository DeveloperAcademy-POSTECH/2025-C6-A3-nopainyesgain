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
    
    /// 아이템 보유 여부 확인
    private var isOwned: Bool {
        guard let user = userManager.currentUser,
              let itemId = item.id else { return false }
        
        if item is KeyringTemplate {
            return user.templates.contains(itemId)
        } else if item is Background {
            return user.backgrounds.contains(itemId)
        } else if item is Carabiner {
            return user.carabiners.contains(itemId)
        } else if item is Particle {
            return user.particleEffects.contains(itemId)
        } else if item is Sound {
            return user.soundEffects.contains(itemId)
        }
        return false
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                itemPreview
                Spacer()
                ItemDetailInfoSection(item: item)
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
    private var itemPreview: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                ZStack {
                    // 파티클이 아닌 경우 이미지 표시
                    if !(item is Particle) {
                        ItemDetailImage(itemURL: getPreviewURL())
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                    }

                    // 파티클 이펙트일 경우 무한 재생
                    if let particle = item as? Particle,
                       let particleId = particle.id {
                        infiniteParticleLottieView(particleId: particleId)
                    }

                    // 사운드일 경우 재생 버튼 표시
                    if item is Sound {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                effectPlayButton
                            }
                        }
                        .padding(.bottom, 93)
                        .padding(.trailing, 16)
                    }
                }

                Spacer()
            }
            .frame(height: 500)
        }
    }

    /// 파티클 무한 재생 뷰
    private func infiniteParticleLottieView(particleId: String) -> some View {
        LottieView(
            name: particleId,
            loopMode: .loop,  // 무한 재생
            speed: 1.0
        )
    }
    
    /// 사운드 재생 버튼
    private var effectPlayButton: some View {
        let itemId = item.id ?? ""
        let isDownloading = effectManager.downloadingItemIds.contains(itemId)
        let progress = effectManager.downloadProgress[itemId] ?? 0.0

        return Button {
            Task {
                if let sound = item as? Sound {
                    await effectManager.playSound(sound, userManager: userManager)
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray50)
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
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
}

// MARK: - Action Button Section
extension WorkshopPreview {
    private var actionButton: some View {
        Group {
            if item.isFree {
                disabledButton(text: "무료")
            } else if isOwned {
                disabledButton(text: "보유중")
            } else {
                purchaseButton
            }
        }
    }
    
    /// 비활성화 버튼 (무료 / 보유중)
    private func disabledButton(text: String) -> some View {
        Button {
            // 비활성화 - 아무 동작 없음
        } label: {
            Text(text)
                .typography(.suit17B)
                .foregroundStyle(.gray400)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(.white100)
        .disabled(true)
    }
    
    /// 구입 버튼 (유료)
    private var purchaseButton: some View {
        Button {
            // TODO: 구매 로직 구현
            print("구매: \(item.name) - \(item.workshopPrice) 코인")
        } label: {
            HStack(spacing: 5) {
                Image(.buyKey)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32)
                
                Text("\(item.workshopPrice)")
                    .typography(.nanum18EB)
                    .foregroundStyle(.white100)
                    .background(Color.gray50)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
        }
        .buttonStyle(.glassProminent)
        .tint(.black80)
    }
}

#Preview {
    // 프리뷰용 샘플 Sound
    let sampleSound = Sound(
        id: "sample_sound_1",
        soundName: "딸랑딸랑",
        description: "귀여운 종소리 효과음",
        soundData: "sample_bell.mp3",
        thumbnail: "https://via.placeholder.com/150",
        tags: ["귀여움", "종소리"],
        price: 100,
        downloadCount: 42,
        useCount: 123,
        createdAt: Date()
    )
    
    return WorkshopPreview(
        router: NavigationRouter<WorkshopRoute>(),
        item: sampleSound
    )
    .environment(UserManager.shared)
}
