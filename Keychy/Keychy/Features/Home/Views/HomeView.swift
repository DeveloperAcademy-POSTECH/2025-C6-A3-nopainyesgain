//
//  HomeView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct HomeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @Bindable var userManager: UserManager
    @Namespace private var unionNamespace
    
    var body: some View {
        ZStack(alignment: .top) {
            // TODO: 뭉치 Scene넣기
            Color.clear
                .frame(maxHeight: .infinity)
            
            HStack(spacing: 10) {
                Spacer()
                
                Button {
                    router.push(.bundleInventoryView)
                } label: {
                    Image(.bundleIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.glassProminent)
                
                GlassEffectContainer {
                    HStack(spacing: 0) {
                        Button {
                            router.push(.alarmView)
                        } label: {
                            Image(.alarmIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.glassProminent)
                        .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)


                        Button {
                            router.push(.myPageView)
                        } label: {
                            Image(.myPageIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                        }
                        
                        .buttonStyle(.glassProminent)
                        .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                    }
                }
            }
            .padding(.horizontal, 16)
            .tint(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
