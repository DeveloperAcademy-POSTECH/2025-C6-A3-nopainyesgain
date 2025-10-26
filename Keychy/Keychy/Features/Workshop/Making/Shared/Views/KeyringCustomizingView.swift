//
//  KeyringCustomizingView.swift
//  KeytschPrototype
//
//  Generic 키링 커스터마이징 화면
//  - 모든 템플릿에서 공통으로 사용 가능
//  - KeyringSceneView도 Generic이므로 주입 불필요
//

import SwiftUI
import SpriteKit

struct KeyringCustomizingView<VM: KeyringViewModelProtocol>: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: VM
    let navigationTitle: String
    let nextRoute: WorkshopRoute

    @State private var selectedInteractionType: Interaction = .tap
    @State private var selectedSoundEffect: SoundEffect = .none
    @State private var selectedParticleEffect: ParticleEffect = .none

    var body: some View {
        VStack(spacing: 0) {
            // SpriteKit Scene (키링 프리뷰) - Generic KeyringSceneView 사용
            ZStack(alignment: .bottomTrailing) {
                KeyringSceneView(viewModel: viewModel)

                // Interaction 선택 버튼 (탭 / 스윙)
                HStack(alignment: .bottom) {
                    ForEach(Interaction.allCases) { Interaction in
                        effectSelectorBtn(for: Interaction)
                    }
                    Spacer()
                }
                .padding(10)
            }

            // MARK: - 효과 선택 영역 (사운드 / 파티클)
            effectSelectorView
        }
        .navigationTitle(navigationTitle)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .toolbar {
            backToolbarItem
            nextToolbarItem
        }
    }
}

// MARK: - Toolbar Section
extension KeyringCustomizingView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
            }
        }
    }

    private var nextToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("다음") {
                router.push(nextRoute)
            }
        }
    }
}

// MARK: - Effects Selector Section
extension KeyringCustomizingView {

    /// Interaction 타입(탭 / 스윙) 선택 버튼
    private func effectSelectorBtn(for InteractionType: Interaction) -> some View {
        Button {
            selectedInteractionType = InteractionType
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(hasEffectApplied(for: InteractionType) ? Color.red.opacity(0.2) : .clear)
                    .stroke(selectedInteractionType == InteractionType ? Color.red : .gray, lineWidth: 1.5)
                    .frame(width: 44, height: 44)

                Image(InteractionType.systemImage)
            }
        }
        // 선택 시 크기 애니메이션
        .scaleEffect(selectedInteractionType == InteractionType ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: selectedInteractionType)
    }

    /// 선택된 Interaction에 따른 효과 선택 화면 (사운드 / 파티클)
    private var effectSelectorView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedInteractionType.title)
                .font(.title2)
                .fontWeight(.bold)

            switch selectedInteractionType {
            case .tap:
                tapEffectView
            case .swing:
                swingEffectView
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(.bar)
    }

    // MARK: - Tap Interaction → 사운드 이펙트 뷰
    private var tapEffectView: some View {
        VStack(alignment: .leading, spacing: 16) {
            soundEffectSelector
        }
    }

    // MARK: - Swing Interaction → 파티클 이펙트 뷰
    private var swingEffectView: some View {
        VStack(alignment: .leading, spacing: 16) {
            particleEffectSelector
        }
    }

    /// 사운드 이펙트 선택 버튼 그룹
    private var soundEffectSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("사운드")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(SoundEffect.allCases, id: \.self) { effect in
                    Button {
                        // 선택 상태 업데이트 및 ViewModel 반영
                        selectedSoundEffect = effect
                        viewModel.updateSoundEffect(effect)
                    } label: {
                        Text(effect.title)
                            .font(.system(size: 13, weight: .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)

                            .foregroundStyle(selectedSoundEffect == effect ? .white : .primary)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(selectedSoundEffect == effect ? Color.red : .gray.opacity(0.2))
                }
            }
        }
    }

    /// 파티클 이펙트 선택 버튼 그룹
    private var particleEffectSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("파티클")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(ParticleEffect.allCases, id: \.self) { effect in
                    Button {
                        selectedParticleEffect = effect
                        viewModel.updateParticleEffect(effect)
                    } label: {
                        Text(effect.title)
                            .font(.system(size: 13, weight: .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundStyle(selectedParticleEffect == effect ? .white : .primary)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(selectedParticleEffect == effect ? Color.red : .gray.opacity(0.2))
                }
            }
        }
    }

    /// Interaction 타입별 효과 적용 여부
    private func hasEffectApplied(for interactionType: Interaction) -> Bool {
        switch interactionType {
        case .tap:
            return selectedSoundEffect != .none
        case .swing:
            return selectedParticleEffect != .none
        }
    }
}
