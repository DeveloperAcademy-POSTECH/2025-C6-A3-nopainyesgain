//
//  PackageCompleteView.swift
//  Keychy
//
//  Created by Jini on 11/7/25.
//

import SwiftUI

struct PackageCompleteView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @State private var currentPage: Int = 0
    
    private let totalPages = 2
    
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
        //.toolbar(.hidden, for: .tabBar)
        
    }
    
    // MARK: - 첫 번째 페이지 (포장 전체 뷰)
    private var packagePreviewPage: some View {
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
