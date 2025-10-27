//
//  WorkshopView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct WorkshopView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    
    var body: some View {
        VStack {
            headerSection
            templateSection
            Spacer()
        }
        .padding(12)
    }
}

// MARK: - Header Section
extension WorkshopView {
    private var headerSection: some View {
        HStack(spacing: 0) {
            Text("키링 공방")
                .font(.title2)
                .bold()
            Spacer()
            
            Image("Cherries")
                .padding(.trailing, 7)
            
            Text("300")
                .foregroundStyle(Color(#colorLiteral(red: 0.9998622537, green: 0.1881143153, blue: 0.3372095823, alpha: 1)))
                .bold()
        }
    }
}

// MARK: - Template Section
extension WorkshopView {
    private var templateSection: some View {
        VStack(spacing: 0) {
            templateHeader
            templateScrollView
        }
        .padding(.top, 18)
    }
    
    private var templateHeader: some View {
        HStack(spacing: 0) {
            Text("내 보유 키링")
                .font(.headline)
                .bold()
            Spacer()
            
            viewAllButton
        }
    }
    
    private var viewAllButton: some View {
        Button("모두 보기") {
                
        }
        .font(.subheadline)
        .tint(.black)
    }
    
    private var templateScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<1, id: \.self) { index in
                    templateButton
                }
            }
            .padding(12)
        }
    }
    
    private var templateButton: some View {
        Button(action: {
            router.push(.arcylicPhotoPreview)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(.white)
                    .stroke(.gray, lineWidth: 1)
                    .frame(width: 91, height: 123)
                
                Image("ddochi")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight:100)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    WorkshopView(router: NavigationRouter<WorkshopRoute>())
}
