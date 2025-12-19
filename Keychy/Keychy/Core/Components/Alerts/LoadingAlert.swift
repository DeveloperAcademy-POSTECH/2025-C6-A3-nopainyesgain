//
//  LoadingAlert.swift
//  Keychy
//
//  Created by 길지훈 on 11/5/25.
//
//
// <아래처럼 사용>
// if isLoadingResources || !isSceneReady {
//      LoadingAlert(type: .longWithKeychy, message: "환영 키링을 만드는 중이에요!")
// }


import SwiftUI
import Lottie

enum LoadingType {
    case short
    case longWithKeychy
    case longWithPresent

    var lottieFileName: String {
        switch self {
        case .short: return "shotLoading"
        case .longWithKeychy: return "longLoadingKeychy"
        case .longWithPresent: return "longLoadingPresent"
        }
    }

    var frameSize: CGFloat {
        switch self {
        case .short: return 48
        case .longWithKeychy: return 122
        case .longWithPresent: return 122
        }
    }
}

struct LoadingAlert: View {
    let type: LoadingType
    let message: String?

    @State private var opacity: Double = 0.0

    var body: some View {
        VStack(spacing: 23) {
            LottieView(
                name: type.lottieFileName,
                loopMode: .loop,
                speed: 1.0
            )
            .frame(width: type.frameSize, height: type.frameSize)

            if type != .short, let message = message {
                Text(message)
                    .typography(.suit17SB)
                    .textOutline(color: .white100, width: 3)
                    .foregroundStyle(.black100)
                    
            }
        }
        .padding(.bottom, message != nil ? 45 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.2)) {
                opacity = 1.0
            }
        }
        .onDisappear {
            withAnimation(.easeOut(duration: 0.15)) {
                opacity = 0.0
            }
        }
    }
}
