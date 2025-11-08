//
//  PackageCompleteView.swift
//  Keychy
//
//  Created by Jini on 11/7/25.
//

import SwiftUI
import SpriteKit

struct PackageCompleteView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @State private var currentPage: Int = 0
    
    private let totalPages = 2
    
    let keyring: Keyring
    
    var body: some View {
        VStack(spacing: 0) {
            Text("키링 포장이 완료되었어요!")
                .typography(.suit20B)
                .foregroundColor(.black100)
                .padding(.bottom, 9)
            
            Text("친구에게 공유하세요")
                .typography(.suit16M)
                .foregroundColor(.black100)
                .padding(.bottom, 42)
            
            
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 38) {
                        // 첫 번째 페이지
                        packagePreviewPage
                            .frame(width: 240)
                        
                        // 두 번째 페이지
                        keyringOnlyPage
                            .frame(width: 240)
                    }
                }
                .content.offset(x: -CGFloat(currentPage) * geometry.size.width / 2)
                .padding(.leading, 10)
                .frame(width: geometry.size.width, alignment: .leading)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let threshold: CGFloat = 38
                            if value.translation.width < -threshold && currentPage < totalPages - 1 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentPage += 1
                                }
                            } else if value.translation.width > threshold && currentPage > 0 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentPage -= 1
                                }
                            }
                        }
                )
            }
            .frame(height: 460)
            
            // 페이지 인디케이터
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.black100 : Color.gray300)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.top, 8)
            
            Spacer()
                .frame(height: 24)
            
            // 버튼들
            HStack(spacing: 16) {
                VStack(spacing: 9) {
                    CircleGlassButton(imageName: "Save", action: {
                        copyLink()
                    })
                    .frame(width: 65, height: 65)
                    
                    Text("링크 복사")
                        .typography(.suit13SB)
                        .foregroundColor(.black100)
                }
                
                VStack(spacing: 9) {
                    CircleGlassButton(imageName: "Save", action: {
                        saveImage()
                    })
                    .frame(width: 65, height: 65)
                    
                    Text("이미지 저장")
                        .typography(.suit13SB)
                        .foregroundColor(.black100)
                }
            }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            backToolbarItem
        }
        .onAppear {
            hideTabBar()
        }
    }
    
    // MARK: - 탭바 제어
    // sheet를 계속 true로 띄워놓으니까 .toolbar(.hidden, for: .tabBar)가 안 먹혀서 강제로 제어하는 코드를 넣음
    private func hideTabBar() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let tabBarController = window.rootViewController?.findTabBarController() {
            UIView.animate(withDuration: 0.3) {
                tabBarController.tabBar.isHidden = true
            }
        }
    }
    
    // MARK: - 첫 번째 페이지 (포장 전체 뷰)
    private var packagePreviewPage: some View {
        VStack(spacing: 0) {
            
//            // 키링 이미지
//            Rectangle()
//                .fill(.gray200)
//                .frame(width: 240, height: 390)
//                .overlay(
//                    Text("키링 이미지만")
//                        .foregroundColor(.gray500)
//                )
//                .padding(.bottom, 30)
            
            KeyringDetailSceneView(keyring: keyring)
                .frame(width: 240, height: 390)
                .cornerRadius(12)
                .padding(.bottom, 30)
                .allowsHitTesting(false)
            
            // 하단 버튼
            Text("링크 복사하기")
                .typography(.suit15M25)
                .foregroundColor(.black100)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 두 번째 페이지 (키링만 있는 뷰)
    private var keyringOnlyPage: some View {
        VStack(spacing: 0) {
            
            // 키링 이미지
            Rectangle()
                .fill(.gray200)
                .frame(width: 240, height: 390)
                .overlay(
                    Text("키링 이미지만")
                        .foregroundColor(.gray500)
                )
                .padding(.bottom, 30)
            
            // 하단 버튼
            Text("QR 코드로 전달하기")
                .typography(.suit15M25)
                .foregroundColor(.black100)
            
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 액션
    private func copyLink() {
        // TODO: 링크 복사 로직
        print("링크 복사")
    }
    
    private func saveImage() {
        // TODO: 이미지 저장 로직
        print("이미지 저장 - 현재 페이지: \(currentPage)")
    }
}

// MARK: - 툴바
extension PackageCompleteView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image("dismiss")
                    .foregroundColor(.primary)
            }
        }
    }
}
