//
//  FestivalKeyringDetailView+Sheet.swift
//  Keychy
//
//  Created by Jini on 11/24/25.
//

import SwiftUI

// MARK: - 바텀시트
extension FestivalKeyringDetailView {
    var infoSheet: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    topSection
                        .padding(.top, sheetDetent == .fraction(0.48) ? 10 : 10)
                        .padding(.bottom, 0)
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
                .frame(minHeight: geometry.size.height)
                .padding(.horizontal, 20)
            }
            .scrollDisabled(true)
        }
        .toolbar(.hidden, for: .tabBar)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white100)
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSheetPresented = false
                    showVoteAlert = true
                }
            }) {
                Image(.voteIcon)
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            
            Spacer()
            
            Text("정보")
                .typography(.suit17B)
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSheetPresented = false
                    showCopyAlert = true
                }
            }) {
                Image(.copyIcon)
                    .resizable()
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.top, 14)
    }
    
    private var basicInfo: some View {
        VStack(spacing: 0) {
            
            Text(keyring.name)
                .typography(.notosans24M)
                .padding(.top, (keyring.senderId != nil && keyring.receivedAt != nil) ? 10 : 30)
            
            Text(formattedDate(date: keyring.createdAt))
                .typography(.suit14M)
            
            Text("@\(authorName)")
                .typography(.notosans14R)
                .foregroundColor(.gray500)
                .padding(.top, 10)
        }
    }
    
    private var memoSection: some View {
        ZStack {
            MemoView(memo: keyring.memo ?? "", sheetDetent: $sheetDetent)
        }
        .padding(.top, 15)
        
    }
    
    private struct MemoView: View {
        let memo: String
        @State private var textHeight: CGFloat = 0
        @State private var scrollOffset: CGFloat = 0
        @Binding var sheetDetent: PresentationDetent
        
        private let minHeight: CGFloat = 60 // 최소 높이
        private let lineHeight: CGFloat = 25
        private let scrollThreshold: CGFloat = 100 // 100포인트 이상 스크롤해야 시트 확대
        
        // 기기별 최대 높이 설정
        private var maxHeight: CGFloat {
            let screenSize = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.screen.bounds.size ?? CGSize(width: 393, height: 852)
            
            // SE
            if screenSize.height <= 667 {
                return 300
            }
            // mini 계열
            else if screenSize.height <= 812 {
                return 380
            }
            // 표준/Pro 계열
            else {
                return 420
            }
        }
        
        private var needsScroll: Bool {
            textHeight > maxHeight
        }
        
        private var displayHeight: CGFloat {
            // 최소 60, 최대 420, 그 사이는 실제 텍스트 높이에 맞춤
            return max(60, min(textHeight + 24, maxHeight))
        }
        
        var body: some View {
            Group {
                if needsScroll {
                    // 스크롤 가능
                    ScrollView {
                        Text(memo.byCharWrapping)
                            .typography(.notosans16R25)
                            .foregroundColor(.black100)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.onAppear {
                                        textHeight = geometry.size.height
                                    }
                                }
                            )
                    }
                    .scrollIndicators(.hidden)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newOffset = value.translation.height
                                
                                // 아래로 스크롤 (음수) && 임계값 초과 && 시트가 최대 높이가 아닐 때
                                if newOffset < -scrollThreshold && sheetDetent != .fraction(0.93) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                        sheetDetent = .fraction(0.93)
                                    }
                                }
                            }
                            .onEnded { _ in
                                scrollOffset = 0  // 제스처 종료 시 리셋
                            }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(height: displayHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray100, lineWidth: 1)
                    )
                } else {
                    // 스크롤 없음
                    Text(memo.byCharWrapping)
                        .typography(.notosans16R25)
                        .foregroundColor(.black100)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: minHeight)
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
