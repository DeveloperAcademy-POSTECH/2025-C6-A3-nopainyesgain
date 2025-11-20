//
//  PhotoSelectSheet.swift
//  Keychy
//
//  사진 등록 시트 (카메라/앨범 선택)
//

import SwiftUI
import PhotosUI

struct PhotoSelectSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onCameraSelected: () -> Void
    let onPhotoLibrarySelected: () -> Void

    @State private var contentHeight: CGFloat = 240

    var body: some View {
        VStack(spacing: 0) {
            // 상단 닫기 버튼
            ZStack(alignment: .topLeading) {
                Button {
                    dismiss()
                } label: {
                    Image("dismiss_gray600")
                }
                .padding(.leading, 20)
                
                // 제목
                HStack {
                    Spacer()
                    Text("사진 넣기")
                        .typography(.suit17B)
                    Spacer()

                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 30)
            .padding(.bottom, 60)

            // 카메라/사진선택 버튼
            HStack(spacing: 12) {
                cameraBtn
                photoPickBtn
            }
            .padding(.horizontal, 35)
            .adaptiveBottomPadding()
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: PhotoSelectHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        )
        .background(Color.white100)
        .presentationBackground(Color.white100)
        .onPreferenceChange(PhotoSelectHeightPreferenceKey.self) { height in
            if height > 0 {
                contentHeight = height
            }
        }
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
    }
}

// MARK: - PreferenceKey
struct PhotoSelectHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 180
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Components
extension PhotoSelectSheet {
    private var cameraBtn: some View {
        Button {
            onCameraSelected()
            dismiss()
        } label: {
            Image("camera")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.glass)
        .clipShape(Circle())
    }

    private var photoPickBtn: some View {
        Button {
            onPhotoLibrarySelected()
            dismiss()
        } label: {
            HStack(spacing: 2) {
                Image("pic")
                Text("사진 선택")
                    .typography(.suit17B)
                    .padding(.vertical, 15)
            }
            .foregroundStyle(.white100)
            .frame(maxWidth: .infinity)
            .background(.gray700)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    Text("Main View")
        .sheet(isPresented: .constant(true)) {
            PhotoSelectSheet(
                onCameraSelected: { print("Camera selected") },
                onPhotoLibrarySelected: { print("Photo library selected") }
            )
        }
}
