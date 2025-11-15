//
//  LoadingAlert.swift
//  Keychy
//
//  Created by 길지훈 on 11/5/25.
//

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
        case .short: return 80
        case .longWithKeychy: return 122
        case .longWithPresent: return 122
        }
    }
}

struct LoadingAlert: View {
    let type: LoadingType
    let message: String?

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
                    .foregroundStyle(.black100)
            }
        }
        .padding(.bottom, message != nil ? 45 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
