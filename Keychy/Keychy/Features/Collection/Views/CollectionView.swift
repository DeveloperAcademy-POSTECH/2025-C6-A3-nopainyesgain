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
    @State private var selectedCategory = "전체"
    @State private var selectedSort: String = "최신순"
    
    let categories: [String] = ["전체", "또치", "폴더", "❤️", "강아지", "여행", "냠냠", "콩순이"]
    
    let bodys: [String] = ["Cherries", "fireworks", "HandSwing", "HandTap", "Cherries", "fireworks", "HandSwing", "HandTap"]
    
    // 정렬 옵션 (최신(생성) / 오래된 / 복사된 숫자순(인기순) / 이름 ㄱㄴㄷ순
    let sortOptions = ["최신순", "오래된순", "이름순"]
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: Spacing.gap),
        GridItem(.flexible(), spacing: Spacing.gap)
    ]
    
    var body: some View {
        VStack {
            headerSection
            tagSection
            collectionSection
        }
        .padding(Spacing.padding)
    }
}

// MARK: - Header Section
extension CollectionView {
    private var headerSection: some View {
        HStack(spacing: 0) {
            Text("보관함")
                .typography(.suit32B)
                .padding(.leading, Spacing.sm)
            
            Spacer()
            
            CircleGlassButton(imageName: "Widget", action: {})
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
    
    // TODO: - 디자인 변경 필요
    private var collectionHeader: some View {
        HStack(spacing: 0) {
            sortButton
            
            Spacer()
            
            Text("36 / 100")
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
                ForEach(bodys.indices, id: \.self) { index in
                    collectionCell(bodyImageName: bodys[index])
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 14)
        .scrollIndicators(.hidden)
    }
    
    private func collectionCell(bodyImageName: String) -> some View {
        Button(action: {
            //router.push(.)
        }) {
            VStack {
                ZStack {
                    SpriteView(scene: createMiniScene(body: bodyImageName))
                        .cornerRadius(10)
                }
                .padding(.bottom, 10)
                
                Text("\(bodyImageName) 키링")
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
    CollectionView(router: NavigationRouter<CollectionRoute>())
}
