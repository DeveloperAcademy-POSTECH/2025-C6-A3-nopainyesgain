//
//  NotificationGiftView.swift
//  Keychy
//
//  Created on 11/18/25.
//

import SwiftUI
import FirebaseFirestore

struct NotificationGiftView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    let postOfficeId: String

    @State private var keyringId: String = ""
    @State private var keyringName: String = ""
    @State private var recipientNickname: String = ""
    @State private var completedDate: Date = Date()
    @State private var isLoading: Bool = true
    @State private var loadError: String?

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            if isLoading {
                LoadingAlert(type: .short, message: nil)
            } else if let error = loadError {
                VStack {
                    Text("선물 정보를 불러올 수 없습니다")
                        .typography(.suit16B)
                    Text(error)
                        .typography(.suit13M)
                        .foregroundStyle(.gray400)
                        .padding(.top, 4)
                }
            } else {
                contentView
            }
        }
        .navigationTitle("키링 선물 완료")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backBtn
        }
        .onAppear {
            fetchGiftData()
        }
    }

    private var contentView: some View {
        VStack(spacing: 24) {
            Spacer()

            // TODO: 포장된 키링 뷰가 여기 나오면 돼요 리엘
            // keyringId << 변수를 선언해두어서 해당 변수로 포장된 키링 가져오면 될듯!
            Rectangle()
                .fill(.gray100)
                .frame(width: 200, height: 280)
                .cornerRadius(12)
                .overlay(
                    Text("포장된 키링 뷰\n(구현 예정)\nkeyringId: \(keyringId)")
                        .typography(.suit13M)
                        .foregroundStyle(.gray400)
                        .multilineTextAlignment(.center)
                )

            // 전달 정보
            VStack(spacing: 4) {
                Text(formattedDate)
                    .typography(.suit16M)
                    .foregroundStyle(.gray400)

                HStack(spacing: 0) {
                    Text("\(recipientNickname)")
                        .typography(.notosans15SB)
                        .foregroundStyle(.gray400)
                    
                    Text("님에게 전달됨")
                        .typography(.suit16M)
                        .foregroundStyle(.gray400)
                }
            }
            Spacer()
        }
    }

    private var backBtn: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CloseToolbarButton {
                router.pop()
            }
            .frame(width: 32, height: 32)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: completedDate)
    }

    private func fetchGiftData() {
        isLoading = true

        // 1. PostOffice 조회
        db.collection("PostOffice").document(postOfficeId).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let keyringId = data["keyringId"] as? String,
                  let receiverId = data["receiverId"] as? String,
                  let endedTimestamp = data["endedAt"] as? Timestamp else {
                self.loadError = "선물 정보를 찾을 수 없습니다"
                self.isLoading = false
                return
            }

            self.completedDate = endedTimestamp.dateValue()
            self.keyringId = keyringId

            // 2. Keyring 조회
            db.collection("Keyring").document(keyringId).getDocument { snapshot, error in
                guard let keyringData = snapshot?.data(),
                      let name = keyringData["name"] as? String else {
                    self.loadError = "키링 정보를 찾을 수 없습니다"
                    self.isLoading = false
                    return
                }

                self.keyringName = name

                // 3. User 조회 (수신자 닉네임)
                db.collection("User").document(receiverId).getDocument { snapshot, error in
                    guard let userData = snapshot?.data(),
                          let nickname = userData["nickname"] as? String else {
                        self.loadError = "사용자 정보를 찾을 수 없습니다"
                        self.isLoading = false
                        return
                    }

                    self.recipientNickname = nickname
                    self.isLoading = false
                }
            }
        }
    }
}
