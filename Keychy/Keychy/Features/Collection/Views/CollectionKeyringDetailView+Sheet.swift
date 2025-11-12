//
//  CollectionKeyringDetailView+Sheet.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI

// MARK: - 바텀시트
extension CollectionKeyringDetailView {
    var infoSheet: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    topSection
                        .padding(.top, sheetDetent == .height(395) ? 10 : 10)
                        .padding(.bottom, sheetDetent == .height(76) ? 14 : 0)
                        .animation(.easeInOut(duration: 0.35), value: sheetDetent)
                    
                    basicInfo
                    
                    // 메모 있으면
                    if let memo = keyring.memo, !memo.isEmpty {
                        memoSection
                    }
                    
                    // 태그 있으면
                    if !keyring.tags.isEmpty {
                        tagSection
                    }
                    
                    Spacer(minLength: 0)
                    
                }
                .padding(.horizontal, 16)
                .frame(minHeight: geometry.size.height)
            }
            .scrollDisabled(true)
        }
        .toolbar(.hidden, for: .tabBar)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sheetDetent == .height(395) ? .white100 : Color.clear)
        .shadow(
            color: Color.black.opacity(0.18),
            radius: 37.5,
            x: 0,
            y: -15
        )
        .animation(.easeInOut(duration: 0.3), value: sheetDetent)

    }
    
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: date)
    }
    
    // 키링 선물 받은 날 포맷팅용
    private func formattedReceiveDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    private var topSection: some View {
        HStack {
            Button(action: {
                captureAndSaveImage()
            }) {
                Image("Save")
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            .opacity(showUIForCapture ? 1 : 0)
            
            Spacer()
            
            Text("정보")
                .typography(.suit17B)
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    sheetDetent = .height(76)
                    showPackageAlert = true
                }
            }) {
                Image("Present")
                    .resizable()
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.top, 14)
    }
    
    private var receiveInfo: some View {
        HStack(spacing: 3) {
            Image("smallPresent")
                .resizable()
                .frame(width: 15, height: 14)
                .padding(.vertical, 2)
            
            Text(senderName)
                .typography(.notosans13M)
                .foregroundColor(.mainOpacity70)
            
            if let receivedAt = keyring.receivedAt {
                Text(formattedReceiveDate(date: receivedAt))
                    .typography(.notosans13M)
                    .foregroundColor(.mainOpacity70)
            }
        }
        .frame(height: 18)
    }
    
    private var basicInfo: some View {
        VStack(spacing: 0) {
            if keyring.senderId != nil && keyring.receivedAt != nil {
                receiveInfo
                    .padding(.top, 10)
            }
            
            Text(keyring.name)
                .typography(.notosans24M)
                .padding(.top, (keyring.senderId != nil && keyring.receivedAt != nil) ? 10 : 30)
            
            Text(formattedDate(date: keyring.createdAt))
                .typography(.suit14M)
            
            Text("@\(authorName)")
                .typography(.notosans14R)
                .foregroundColor(.gray300)
                .padding(.top, 10)
        }
    }
    
    private var memoSection: some View {
        ZStack {
            MemoView(memo: keyring.memo ?? "")
        }
        .padding(.top, 15)
        
    }
    
    private struct MemoView: View {
        let memo: String
        @State private var textHeight: CGFloat = 0
        
        private var needsScroll: Bool {
            textHeight > 76 // 3줄 정도의 높이
        }
        
        private var displayHeight: CGFloat {
            if textHeight <= 36 { // 1줄
                return 60
            } else if textHeight <= 60 { // 2줄
                return 80
            } else if textHeight <= 76 { // 3줄
                return 100
            } else { // 4줄 이상
                return 100
            }
        }
        
        var body: some View {
            Group {
                if needsScroll {
                    // 4줄 이상일 때 스크롤 가능
                    ScrollView {
                        Text(memo)
                            .typography(.notosans16R25)
                            .foregroundColor(.black100)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.onAppear {
                                        textHeight = geometry.size.height
                                    }
                                }
                            )
                    }
                    .scrollIndicators(.hidden)
                    .frame(height: displayHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray100, lineWidth: 1)
                    )
                } else {
                    // 3줄 이하일 때 스크롤 없음
                    Text(memo)
                        .typography(.suit16M25)
                        .foregroundColor(.black100)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true) // 수직으로 확장
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: TextHeightPreferenceKey.self,
                                    value: geometry.size.height
                                )
                            }
                        )
                        .onPreferenceChange(TextHeightPreferenceKey.self) { height in
                            textHeight = height
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.gray100, lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var tagSection: some View {
        TagScrollView(tags: keyring.tags)
            .padding(.top, 15)
    }
    
    private struct TagScrollView: View {
        let tags: [String]
        @State private var contentWidth: CGFloat = 0
        @State private var containerWidth: CGFloat = 0
        
        // 가로 스크롤 여부 검사
        // 화면을 삐져나가면 스크롤 적용 후 왼쪽정렬, 아니면 스크롤 없이 가운데정렬
        private var needsScroll: Bool {
            contentWidth > containerWidth
        }
        
        var body: some View {
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(tagName: tag)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear.onAppear {
                                contentWidth = contentGeometry.size.width
                            }
                        }
                    )
                    .frame(minWidth: needsScroll ? nil : geometry.size.width)
                }
                .frame(width: geometry.size.width, alignment: needsScroll ? .leading : .center)
                .disabled(!needsScroll)
                .onAppear {
                    containerWidth = geometry.size.width
                }
            }
            .frame(height: 36)
        }
    }
    
    private struct TagChip: View {
        let tagName: String
        
        var body: some View {
            ZStack {
                Text(tagName)
                    .typography(.malang15B)
                    .foregroundColor(.main700)
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.mainOpacity15)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.mainOpacity50, lineWidth: 1.5)
                    )
            }
        }

    }
}
