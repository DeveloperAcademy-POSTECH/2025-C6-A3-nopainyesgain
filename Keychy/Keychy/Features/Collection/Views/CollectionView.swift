//
//  CollectionView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI
import SpriteKit

struct CollectionView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @Bindable var collectionViewModel: CollectionViewModel
    @State private var selectedCategory = "전체"
    @State private var selectedSort: String = "최신순"
    
    let categories: [String] = ["전체", "또치", "tags", "❤️", "강아지", "여행", "냠냠", "콩순이"]
    
    // 정렬 옵션 (최신(생성) / 오래된 / 복사된 숫자순(인기순) / 이름 ㄱㄴㄷ순
    let sortOptions = ["최신순", "오래된순", "이름순"]
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: Spacing.gap),
        GridItem(.flexible(), spacing: Spacing.gap)
    ]
    
    // TODO: 파이어베이스 연결해서 내 키링 불러오기
    private var myKeyrings: [Keyring] {
        var keyrings = collectionViewModel.keyring
        
        // 카테고리 필터링
        if selectedCategory != "전체" {
            keyrings = keyrings.filter { $0.tags.contains(selectedCategory) }
        }
        
        return keyrings
    }
    
    var body: some View {
        VStack {
            headerSection
            tagSection
            collectionSection
        }
        .padding(Spacing.padding)
        .onAppear {
            loadUserKeyrings()
        }
    }
    
    // MARK: - 키링 로드 함수
    private func loadUserKeyrings() {
        // UserDefaults에서 uid 가져오기
        guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
            print("UID를 찾을 수 없습니다")
            return
        }
        
        print("CollectionView - 키링 로드 시작")
        
        collectionViewModel.loadUserKeyrings(uid: uid) { success in
            if success {
                print("CollectionView - 키링 로드 완료: \(collectionViewModel.keyring.count)개")
            } else {
                print("CollectionView - 키링 로드 실패")
            }
        }
    }
    
//    // MARK: - 테스트 키링 생성 함수
//    private func createTestKeyring() {
//        guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
//            print("UID를 찾을 수 없습니다")
//            return
//        }
//        
//        print("테스트 키링 생성 시작")
//        
//        // 랜덤 데이터 생성
//        let randomNames = ["또치", "콩순이", "체리", "파이어워크", "강아지", "고양이", "토끼", "곰돌이"]
//        let randomTags = ["또치", "tags", "❤️", "강아지", "여행", "냠냠", "콩순이"]
//        let randomEmojis = ["🎨", "🌟", "💖", "🎵", "🍀", "🌈", "⭐️", "💫"]
//        let randomImage = ["Cherries", "Bundle", "Widget", "InvenPlus"]
//        
//        let randomName = randomNames.randomElement() ?? "테스트"
//        let randomNumber = Int.random(in: 1...1000)
//        
//        let keyringName = "\(randomName) \(randomEmojis.randomElement() ?? "✨") #\(randomNumber)"
//        
//        // 임의의 태그 1-3개 선택
//        let shuffledTags = randomTags.shuffled()
//        let selectedTags = Array(shuffledTags.prefix(Int.random(in: 1...3)))
//        let randomBodies = randomImage[Int.random(in: 0...3)]
//        
//        collectionViewModel.createKeyring(
//            uid: uid,
//            name: keyringName,
//            bodyImage: randomBodies,
//            soundId: "fsdlkanv;",
//            particleId: "ewflkdflkvl",
//            memo: "테스트로 생성된 키링입니다. \n생성 시간: \(Date().formatted())",
//            tags: selectedTags,
//            selectedTemplate: "cnvkla",
//            selectedRing: "fsdflkdnvls",
//            selectedChain: "sdfmlksdvlksd",
//            chainLength: 5
//        ) { success, keyringId in
//            
//            if success {
//                print("테스트 키링 생성 완료 - ID: \(keyringId ?? "unknown")")
//                
//                // 키링 목록 새로고침
//                loadUserKeyrings()
//            } else {
//                print("테스트 키링 생성 실패")
//            }
//        }
//    }
}


// MARK: - Header Section
extension CollectionView {
    private var headerSection: some View {
        HStack(spacing: 0) {
            Text("보관함")
                .typography(.suit32B)
                .padding(.leading, Spacing.sm)
            
            Spacer()
            
            CircleGlassButton(imageName: "Widget", action: {
                //print("테스트 키링 생성")
                //createTestKeyring()
            })
                .padding(.trailing, 10)
            
            CircleGlassButton(imageName: "Bundle", action: {})
        }
    }
}

// MARK: - Tags Section
extension CollectionView {
    
    private var tagSection: some View {
        CategoryTabBar(
            categories: categories,
            selectedCategory: $selectedCategory
        )
        .padding(.top, Spacing.xs)
        .padding(.horizontal, 2)
    }
}

// MARK: - Collection Section
extension CollectionView {
    
    private var collectionSection: some View {
        VStack(spacing: 0) {
            collectionHeader
            collectionGridView
        }
        .padding(.top, Spacing.xs)
        .padding(.horizontal, Spacing.xs)
    }
    
    private var collectionHeader: some View {
        HStack(spacing: 0) {
            sortButton
            
            Spacer()
            
            Text("\(myKeyrings.count) / 100")
                .typography(.suit14SB18)
                .foregroundColor(.black100)
                .padding(.trailing, 8)

            Image("InvenPlus")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        }
    }
    
    // 정렬 버튼
    private var sortButton: some View {
        Button(action: {
            // TODO: - 정렬 로직 추가
        }) {
            HStack(spacing: 2) {
                Text(selectedSort)
                    .typography(.suit14SB18)
                    .foregroundColor(.white100)
                
                Image("ChevronDown")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, Spacing.gap)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.black70)
            )
            
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var collectionGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 11) {
                ForEach(myKeyrings, id: \.name) { keyring in
                    collectionCell(keyring: keyring)
                }
            }
        }
        .padding(.top, 14)
        .scrollIndicators(.hidden)
    }
    
    private func collectionCell(keyring: Keyring) -> some View {
        Button(action: {
            router.push(.collectionKeyringDetailView)
        }) {
            VStack {
                ZStack {
                    SpriteView(scene: createMiniScene(body: keyring.bodyImage))
                        .cornerRadius(10)
                    
                    // 포장 or 출품 상태에 따라 비활성 뷰 오버레이
                    if let info = keyring.status.overlayInfo {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.black20)
                            .overlay {
                                VStack() {
                                    ZStack {
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 10,
                                            topTrailingRadius: 10
                                        )
                                        .fill(Color.black60)
                                        .frame(height: 26)
                                        
                                        Text(info)
                                            .typography(.suit13M)
                                            .foregroundColor(.white100)
                                            .frame(height: 26)
                                    }
                                    Spacer()
                                }
                            }
                    }
                
                }
                .padding(.bottom, 10)
                
                Text("\(keyring.name) 키링")
                    .typography(.suit14SB18)
                    .foregroundColor(.black100)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 175, height: 261)
    }
    
    private func createMiniScene(body: String) -> KeyringCellScene {
        let scene = KeyringCellScene(
            bodyImage: UIImage(named: body),
            targetSize: CGSize(width: 175, height: 233),
            zoomScale: 2.0
        )
        scene.scaleMode = .aspectFill
        return scene
    }
}

// MARK: - Preview
#Preview {
    CollectionView(router: NavigationRouter<CollectionRoute>(), collectionViewModel: CollectionViewModel())
}
