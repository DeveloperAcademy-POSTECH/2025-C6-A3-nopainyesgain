//
//  FestivalKeyringDetailView.swift
//  Keychy
//
//  Created by seo on 11/23/25.
//

import SwiftUI
import NukeUI

struct FestivalKeyringDetailView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: Showcase25BoardViewModel
    
    @State var authorName: String = ""
    @State var keyring: Keyring?
    
    @State var showVoteAlert: Bool = false
    
    // keyringDetailView에 이거 있길래 데려왔는데 필요 없으면 지우세욥!!
    let heightRatio: CGFloat = screenHeight / 852
    // geometryReader 안 써도 screenWidth, screenHeight 전역으로 선언해둿어용 쓰시면 돼용
    var body: some View {
        ZStack {
            VStack {
                if let keyring = keyring {
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
                    ProgressView()
                }
            }
            .padding(.horizontal, 80)
            
            customNavigationBar
        }
        .task {
            // 뷰가 나타날 때 선택된 키링 로드
            keyring = await viewModel.getSelectedKeyring()
        }
    }
}

//MARK: 커스텀 네비바
extension FestivalKeyringDetailView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center: {
            Text(keyring?.name ?? "키링 상세")
        } trailing: {
            
        }
    }
}
