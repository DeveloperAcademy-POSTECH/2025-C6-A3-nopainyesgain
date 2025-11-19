//
//  View+SafeAreaBottom.swift
//  Keychy
//
//  Created by 길지훈 on 11/16/25.
//

import SwiftUI

extension View {
    // 직각형 기기(SE2, 3? 더 있나)에서만 패딩 추가합니다.

    /// 하단
    func adaptiveBottomPadding(_ defaultPadding: CGFloat = 34) -> some View {
        self.padding(.bottom, getBottomPadding(defaultPadding))
    }

    /// 상단 - 기본 (safeAreaInsets.top == 0 체크)
    func adaptiveTopPadding(_ defaultPadding: CGFloat = 20) -> some View {
        self.padding(.top, getTopPadding(defaultPadding))
    }
    
    /// 제가 테스트 햇을땐 이게 딱 맞았음. 그냥 Alt버전은 SE만 대응이 된다.
    func adaptiveTopPaddingAlt(_ defaultPadding: CGFloat = 39) -> some View {
        self.padding(.top, getTopPaddingAlt(defaultPadding))
    }

    /// 하단 safeArea 값 반환
    func getBottomPadding(_ defaultPadding: CGFloat) -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return defaultPadding
        }
        // safeAreaInsets.bottom이 0이면 직각형 기기임!
        return window.safeAreaInsets.bottom == 0 ? defaultPadding : 0
    }
    
    // MARK: - 다음 머지에서 검색해서 안쓰면 삭제
    /// 상단 safeArea 값 반환
    func getTopPadding(_ defaultPadding: CGFloat) -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return defaultPadding
        }
        
        // safeAreaInsets.top이 0이면 직각형 기기임!
        return window.safeAreaInsets.top == 0 ? defaultPadding : 0
    }
    

    // 번들에서 사용하는 safeAreaTop 함수
    func getTopPaddingBundle(_ defaultPadding: CGFloat) -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return defaultPadding
        }

        // 실제 safeArea top 값 + 추가 패딩
        return window.safeAreaInsets.bottom == 0 ? window.safeAreaInsets.top + defaultPadding : 0
    }
    
    /// 기기의 safeAreaInsets.top을 계산하고 defaultPadding을 더해서 탑패딩을 한다.
    func getTopPaddingAlt(_ defaultPadding: CGFloat) -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return defaultPadding
        }

        // 실제 safeArea top 값 + 추가 패딩
        return window.safeAreaInsets.top + defaultPadding
    }
}
