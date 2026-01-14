//
//  TermsView.swift
//  Keychy
//
//  Created by Rundo on 11/6/25.
//

import SwiftUI

/// 개인정보 처리 방침 및 이용약관
struct TermsView: View {
    var router: NavigationRouter<HomeRoute>?
    @State private var isEnglish = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                appIcon
                privacyPolicySection
                Divider().padding(.vertical, 20)
                termsSection
            }
            .padding(20)
        }
        .navigationTitle(isEnglish ? "Privacy Policy & Terms" : "개인정보 처리 방침 및 이용약관")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backToolbarItem
            engToggleToolbarItem
        }
        .onAppear {
            TabBarManager.hide()
        }
    }

    private var appIcon: some View {
        Image(.appIcon)
            .resizable()
            .scaledToFit()
            .frame(width: 100, alignment: .center)
    }
}

// MARK: - Privacy Policy
extension TermsView {
    private var privacyPolicySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionTitle(isEnglish ? "Privacy Policy" : "개인정보 처리방침")
                Spacer()
                if router == nil {
                    Button {
                        isEnglish.toggle()
                    } label: {
                        Text(isEnglish ? "KOR" : "ENG")
                            .typography(.suit14B)
                            .foregroundStyle(.main500)
                    }
                }
            }
            intro
            informationCollection
            thirdPartyAccess
            optOutRights
            dataRetention
            children
            security
            changes
            consent
            contactPrivacy
        }
    }

    private var intro: some View {
        bodyText(isEnglish ?
            "This privacy policy applies to the Keychy app (hereby referred to as \"Application\") for mobile devices that was created by Gaeun Joo (hereby referred to as \"Service Provider\") as a Freemium service. This service is intended for use \"AS IS\"." :
            "본 개인정보 처리방침은 Gaeun Joo(이하 \"서비스 제공자\")가 Freemium 서비스로 제작한 모바일 기기용 Keychy 앱(이하 \"애플리케이션\")에 적용됩니다. 본 서비스는 \"있는 그대로(AS IS)\" 사용을 목적으로 합니다.")
    }

    private var informationCollection: some View {
        Group {
            subSectionTitle(isEnglish ? "Information Collection and Use" : "정보 수집 및 이용")

            bodyText(isEnglish ?
                "The Application collects information when you download and use it. This information may include:" :
                "애플리케이션은 사용자가 다운로드하고 사용할 때 정보를 수집합니다:")

            bulletPoint(isEnglish ?
                "Your device's Internet Protocol address (e.g. IP address)" :
                "사용자 기기의 IP 주소")
            bulletPoint(isEnglish ?
                "The pages of the Application that you visit, the time and date of your visit, the time spent on those pages" :
                "방문한 페이지, 일시, 체류 시간")
            bulletPoint(isEnglish ?
                "The time spent on the Application" :
                "앱 사용 시간")
            bulletPoint(isEnglish ?
                "The operating system you use on your mobile device" :
                "모바일 기기 운영체제")

            bodyText(isEnglish ?
                "The Application collects your device's location for:" :
                "위치 정보는 다음과 같이 활용됩니다:")
            bulletPoint(isEnglish ?
                "Geolocation Services: Providing personalized content, relevant recommendations, and location-based services" :
                "개인화된 콘텐츠 및 위치 기반 서비스 제공")
            bulletPoint(isEnglish ?
                "Analytics and Improvements: Analyzing user behavior, identifying trends, and improving performance" :
                "사용자 행동 분석 및 성능 개선")
            bulletPoint(isEnglish ?
                "Third-Party Services: Transmitting anonymized location data to external services" :
                "제3자 서비스와의 익명화된 데이터 공유")
        }
    }

    private var thirdPartyAccess: some View {
        Group {
            subSectionTitle(isEnglish ? "Third Party Access" : "제3자 접근")

            bodyText(isEnglish ?
                "Only aggregated, anonymized data is periodically transmitted to external services. The Application utilizes third-party services:" :
                "집계·익명화된 데이터가 외부 서비스로 전송될 수 있습니다. 사용하는 제3자 서비스:")
            bulletPoint("Google Analytics for Firebase")
            bulletPoint("Firebase Crashlytics")
        }
    }

    private var optOutRights: some View {
        Group {
            subSectionTitle(isEnglish ? "Opt-Out Rights" : "수집 거부 권리")
            bodyText(isEnglish ?
                "You can stop all collection of information by the Application easily by uninstalling it." :
                "앱을 삭제하면 모든 정보 수집이 중단됩니다.")
        }
    }

    private var dataRetention: some View {
        Group {
            subSectionTitle(isEnglish ? "Data Retention Policy" : "데이터 보유 정책")
            bodyText(isEnglish ?
                "To delete your data, please contact us at keychy.official@gmail.com" :
                "데이터 삭제를 원하시면 keychy.official@gmail.com으로 연락 주시기 바랍니다.")
        }
    }

    private var children: some View {
        Group {
            subSectionTitle(isEnglish ? "Children" : "어린이")
            bodyText(isEnglish ?
                "The Service Provider does not knowingly collect data from or market to children under the age of 13." :
                "13세 미만 아동으로부터 고의로 데이터를 수집하지 않습니다.")
        }
    }

    private var security: some View {
        Group {
            subSectionTitle(isEnglish ? "Security" : "보안")
            bodyText(isEnglish ?
                "The Service Provider provides physical, electronic, and procedural safeguards to protect your information." :
                "정보 보호를 위해 물리적·전자적·절차적 보호 장치를 제공합니다.")
        }
    }

    private var changes: some View {
        Group {
            subSectionTitle(isEnglish ? "Changes" : "변경 사항")
            bodyText(isEnglish ?
                "This Privacy Policy may be updated from time to time. Changes will be posted on this page." :
                "개인정보 처리방침은 수시로 업데이트될 수 있으며, 변경 사항은 본 페이지에 게시됩니다.")
            bodyText(isEnglish ?
                "This privacy policy is effective as of 2025-11-09" :
                "본 개인정보 처리방침은 2025-11-09부터 유효합니다.")
        }
    }

    private var consent: some View {
        Group {
            subSectionTitle(isEnglish ? "Your Consent" : "동의")
            bodyText(isEnglish ?
                "By using the Application, you are consenting to the processing of your information as set forth in this Privacy Policy." :
                "애플리케이션을 사용함으로써, 귀하는 본 개인정보 처리방침에 따라 정보가 처리되는 것에 동의합니다.")
        }
    }

    private var contactPrivacy: some View {
        Group {
            subSectionTitle(isEnglish ? "Contact Us" : "문의하기")
            bodyText(isEnglish ?
                "If you have any questions regarding privacy, please contact us at keychy.official@gmail.com" :
                "문의사항은 keychy.official@gmail.com으로 연락 주시기 바랍니다.")
        }
    }
}

// MARK: - Terms & Conditions
extension TermsView {
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(isEnglish ? "Terms & Conditions" : "이용약관")

            termsIntro
            intellectualProperty
            serviceChanges
            userResponsibility
            thirdPartyServices
            network
            deviceResponsibility
            updates
            termsChanges
            contactTerms
        }
    }

    private var termsIntro: some View {
        bodyText(isEnglish ?
            "These terms and conditions apply to the Keychy app created by Gaeun Joo as a Freemium service. Upon downloading or utilizing the Application, you are automatically agreeing to the following terms." :
            "본 이용약관은 Gaeun Joo가 제작한 Keychy 앱에 적용됩니다. 앱을 사용하는 경우 본 약관에 동의한 것으로 간주됩니다.")
    }

    private var intellectualProperty: some View {
        Group {
            subSectionTitle(isEnglish ? "Intellectual Property" : "지식재산권")
            bodyText(isEnglish ?
                "Unauthorized copying, modification of the Application, or our trademarks is strictly prohibited. All intellectual property rights remain the property of the Service Provider." :
                "앱 및 관련 저작물의 무단 복제·수정·변형은 금지됩니다. 모든 지식재산권은 서비스 제공자에게 귀속됩니다.")
        }
    }

    private var serviceChanges: some View {
        Group {
            subSectionTitle(isEnglish ? "Service Changes and Fees" : "서비스 변경 및 요금")
            bodyText(isEnglish ?
                "The Service Provider reserves the right to modify the Application or charge for services at any time. Any charges will be clearly communicated to you." :
                "서비스 제공자는 언제든 앱 기능을 변경하거나 요금을 부과할 수 있으며, 이 경우 사전에 안내합니다.")
        }
    }

    private var userResponsibility: some View {
        Group {
            subSectionTitle(isEnglish ? "User Responsibility" : "사용자 책임")
            bodyText(isEnglish ?
                "You are responsible for maintaining the security of your device and Application access. Jailbreaking or rooting your device may compromise security and cause the Application to malfunction." :
                "사용자는 기기와 앱 접근 권한을 안전하게 관리해야 합니다. 탈옥·루팅은 앱이 정상 작동하지 않을 수 있습니다.")
        }
    }

    private var thirdPartyServices: some View {
        Group {
            subSectionTitle(isEnglish ? "Third-Party Services" : "제3자 서비스")
            bodyText(isEnglish ?
                "The Application utilizes third-party services:" :
                "앱은 다음 제3자 서비스를 이용합니다:")
            bulletPoint("Google Analytics for Firebase")
            bulletPoint("Firebase Crashlytics")
        }
    }

    private var network: some View {
        Group {
            subSectionTitle(isEnglish ? "Network and Usage Environment" : "네트워크 및 사용 환경")
            bodyText(isEnglish ?
                "Some functions require an active internet connection. Data charges may apply when using the app without Wi-Fi, including roaming charges when used outside your home territory." :
                "일부 기능은 인터넷 연결이 필요하며, 데이터 요금이 발생할 수 있습니다. 로밍 시 추가 요금이 부과될 수 있습니다.")
        }
    }

    private var deviceResponsibility: some View {
        Group {
            subSectionTitle(isEnglish ? "Device Responsibility" : "기기 상태 및 이용 책임")
            bodyText(isEnglish ?
                "It is your responsibility to ensure your device remains charged. The Service Provider accepts no liability for any loss resulting from relying on the Application's functionality." :
                "기기 충전 상태 유지는 사용자 책임입니다. 제공 정보의 정확성에 대해 완전한 책임을 지지 않습니다.")
        }
    }

    private var updates: some View {
        Group {
            subSectionTitle(isEnglish ? "Updates and Termination" : "업데이트 및 종료")
            bodyText(isEnglish ?
                "The Service Provider may update or terminate the Application at any time. The Application is not guaranteed to be compatible with your device or operating system version." :
                "서비스 제공자는 앱을 업데이트하거나 종료할 수 있으며, 기기 호환성을 보장하지 않습니다.")
        }
    }

    private var termsChanges: some View {
        Group {
            subSectionTitle(isEnglish ? "Changes to Terms and Conditions" : "약관 변경")
            bodyText(isEnglish ?
                "The Service Provider may periodically update these Terms and Conditions. Changes will be posted on this page." :
                "본 이용약관은 수시로 수정될 수 있으며, 변경 후 계속 사용 시 수정된 약관에 동의한 것으로 간주됩니다.")
            bodyText(isEnglish ?
                "These terms and conditions are effective as of 2025-11-09" :
                "본 이용약관은 2025년 11월 9일부로 시행됩니다.")
        }
    }

    private var contactTerms: some View {
        Group {
            subSectionTitle(isEnglish ? "Contact Us" : "문의하기")
            bodyText(isEnglish ?
                "If you have any questions about the Terms and Conditions, please contact us at keychy.official@gmail.com" :
                "문의사항은 keychy.official@gmail.com으로 연락 주시기 바랍니다.")
        }
    }
}

// MARK: - Style Components
extension TermsView {
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .typography(.suit18B)
            .padding(.top, 8)
    }

    private func subSectionTitle(_ text: String) -> some View {
        Text(text)
            .typography(.suit16B)
            .padding(.top, 12)
    }

    private func bodyText(_ text: String) -> some View {
        Text(text)
            .typography(.suit14M)
            .lineSpacing(6)
            .foregroundColor(.black80)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .typography(.suit14M)
            Text(text)
                .typography(.suit14M)
                .lineSpacing(6)
                .foregroundColor(.black80)
        }
    }
}

// MARK: - Toolbar Items
extension TermsView {
    var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router?.pop()
            } label: {
                Image(.backIcon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
        }
    }
    
    var engToggleToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isEnglish.toggle()
            } label: {
                Text(isEnglish ? "KOR" : "ENG")
                    .typography(.suit14B)
                    .foregroundStyle(.main500)
            }
        }
    }
}
