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
    @State private var selectedChip: String = "전체"
    
    let chips: [String] = ["전체", "또치", "폴더", "❤️", "강아지", "여행", "냠냠", "콩순이"]
    
    let bodys: [String] = ["Cherries", "fireworks", "HandSwing", "HandTap", "Cherries", "fireworks", "HandSwing", "HandTap"]
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            headerSection
            tagSection
            collectionSection
        }
        .padding(16)
    }
}

// MARK: - Header Section
extension CollectionView {
    private var headerSection: some View {
        HStack(spacing: 0) {
            Spacer()
            
            widgetButton
                .padding(.trailing, 10)
            
            bundleButton
        }
        .overlay(
            Text("보관함")
                .font(.title2)
                .bold()
        )
    }
    
    // TODO: - 버튼 디자인 변경 필요
    private var widgetButton: some View {
        Button(action: {
            //router.push(.)
        }) {
            ZStack {
                Circle()
                    //.stroke(.gray, lineWidth: 1)
                    .frame(width: 44, height: 44)
                    .glassEffect(.clear)
                
                Image("HandSwing")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // TODO: - 버튼 디자인 변경 필요
    private var bundleButton: some View {
        Button(action: {
            //router.push(.)
        }) {
            ZStack {
                Circle()
                    //.stroke(.gray, lineWidth: 1)
                    .frame(width: 44, height: 44)
                    .glassEffect(.clear)
                
                Image("HandTap")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tags Section
extension CollectionView {
    
    private var tagSection: some View {
        VStack(spacing: 4) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 8) {
                    ForEach(chips, id: \.self) { chip in
                        chipButton(for: chip)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 52)
            .scrollIndicators(.hidden)
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
            // TODO: - Divider 화면 양끝까지 영역 설정
                .frame(height: 3)
                .edgesIgnoringSafeArea(.horizontal)
        }

    }
    
    // TODO: - 디자인 변경 필요
    private func chipButton(for chip: String) -> some View {
        Button(action: {
            selectedChip = chip
        }) {
            ZStack {
                Text(chip)
                    .font(.body)
                    .foregroundColor(selectedChip == chip ? .white : .gray)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedChip == chip ? .pink : .white)
                            .stroke(selectedChip == chip ? .clear : .gray, lineWidth: 1)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Collection Section
extension CollectionView {
    
    private var collectionSection: some View {
        VStack(spacing: 0) {
            collectionHeader
            collectionGridView
        }
        .padding(.top, 4)
    }
    
    // TODO: - 디자인 변경 필요
    private var collectionHeader: some View {
        HStack(spacing: 0) {
            Text("36 / 100")
                .font(.headline)
                .bold()
                .padding(.trailing, 5)
            ZStack {
                Circle()
                    .fill(.pink)
                    .frame(width: 15, height: 15)
                Text("+")
                    .foregroundColor(.white)
                    .font(.caption2)
            }
            Spacer()
            
            sortButton
        }
    }
    
    // TODO: - 디자인 변경 및 로직 추가
    private var sortButton: some View {
        Button("최신 순") {
            // TODO: - 로직 추가 필요
        }
        .font(.subheadline)
        .tint(.black)
    }
    
    private var collectionGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
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
                        .cornerRadius(5)
                }
                HStack {
                    Text("\(bodyImageName) 키링")
                        .font(.headline)
                    Spacer()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 172, height: 257)
    }
    
    private func createMiniScene(body: String) -> KeyringCellScene {
        let scene = KeyringCellScene(
            bodyImage: UIImage(named: body),
            targetSize: CGSize(width: 172, height: 225),
            zoomScale: 1.8
        )
        scene.scaleMode = .aspectFill
        return scene
    }
}

// MARK: - Preview
#Preview {
    CollectionView(router: NavigationRouter<CollectionRoute>())
}
