//
//  FestivalKeyringDetailView.swift
//  Keychy
//
//  Created by seo on 11/23/25.
//

import SwiftUI
import NukeUI

struct FestivalKeyringDetailView: View {
    @Bindable var festivalRouter: NavigationRouter<FestivalRoute>
    @Bindable var workshopRouter: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: Showcase25BoardViewModel
    
    @State private var authorName: String = ""
    @State private var keyring: Keyring?
    @State private var isLoading: Bool = true
    
    @State var showVoteAlert: Bool = false
    
    // keyringDetailView에 이거 있길래 데려왔는데 필요 없으면 지우세욥!!
    let heightRatio: CGFloat = screenHeight / 852
    // geometryReader 안 써도 screenWidth, screenHeight 전역으로 선언해둿어용 쓰시면 돼용
    var body: some View {
        ZStack {
            VStack {
                if isLoading {
                    ProgressView()
                } else if let keyring = keyring {
                    // 정보 잘 나오는지 확인하는 용으로 해둔 임의 디자인이에용 수정하시면 됩니닷
                    LazyImage(url: URL(string: keyring.bodyImage)) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .frame(height: screenHeight * 0.3)
                        }
                    }
                    Text("키링 제출자 : \(authorName)")
                } else {
                    Text("키링을 찾을 수 없습니다.")
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal, 80)
            
            customNavigationBar
        }
        .task {
            // 뷰가 나타날 때 선택된 키링 로드
            await loadKeyringDetail()
        }
    }
    
    // MARK: - 키링 로드
    @MainActor
    private func loadKeyringDetail() async {
        isLoading = true
        
        // 뷰모델에서 선택된 ShowcaseFestivalKeyring을 가져옴
        guard let showcaseKeyring = viewModel.selectedShowcaseKeyring else {
            isLoading = false
            return
        }
        
        // ShowcaseFestivalKeyring을 실제 Keyring으로 변환
        keyring = await viewModel.convertToKeyring(from: showcaseKeyring)
        
        // authorId로 작성자 이름 가져오기 (필요하면 구현)
        authorName = showcaseKeyring.authorId // 임시로 ID를 보여줌. 나중에 User 데이터에서 이름 가져오기
        
        isLoading = false
    }
}

//MARK: 커스텀 네비바
extension FestivalKeyringDetailView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                festivalRouter.pop()
            }
        } center: {
            Text(keyring?.name ?? "키링 상세")
        } trailing: {
            
        }
    }
}
