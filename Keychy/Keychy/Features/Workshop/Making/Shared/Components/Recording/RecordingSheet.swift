//
//  RecordingSheet.swift
//  Keychy
//
//  음성 녹음 시트 UI
//

import SwiftUI
import AVFAudio

struct RecordingSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var recorder = AudioRecorderManager()

    @State private var showPermissionAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var sheetHeight: CGFloat = 300

    let onApply: (URL) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 상단 닫기 버튼
            HStack {
                dismissButton
                    .padding(.top, 30)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.bottom, 20)

            // 타이틀
            Text("음성 메모 녹음")
                .typography(.suit20B)
                .padding(.bottom, 30)

            // 녹음 상태에 따른 컨텐츠
            recordingContent
                .padding(.bottom, 40)

            // 버튼들
            actionButtons
                .padding(.horizontal, 35)
                .padding(.bottom, 30)
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: RecordingSheetHeightKey.self,
                    value: geometry.size.height
                )
            }
        )
        .onPreferenceChange(RecordingSheetHeightKey.self) { height in
            if height > 0 {
                sheetHeight = height
            }
        }
        .presentationDetents([.height(sheetHeight)])
        .alert("마이크 권한 필요", isPresented: $showPermissionAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("음성을 녹음하려면 마이크 접근 권한이 필요합니다.")
        }
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Components
extension RecordingSheet {
    private var dismissButton: some View {
        Button {
            if recorder.isRecording {
                recorder.cancelRecording()
            }
            dismiss()
        } label: {
            Image("dismiss")
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private var recordingContent: some View {
        VStack(spacing: 20) {
            // 타이머 표시
            Text(formatTime(recorder.recordingTime))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(recorder.isRecording ? .red : .gray300)
                .monospacedDigit()

            // 상태 텍스트
            Text(statusText)
                .typography(.suit16M)
                .foregroundStyle(.gray500)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if recorder.hasRecording() {
            // 녹음 완료 후: 재생/삭제/적용
            completedButtons
        } else if recorder.isRecording {
            // 녹음 중: 중지 버튼
            stopButton
        } else {
            // 녹음 전: 시작 버튼
            startButton
        }
    }

    // 녹음 시작 버튼
    private var startButton: some View {
        Button {
            Task {
                await startRecordingWithPermission()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                Text("녹음 시작")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.red)
            .clipShape(Capsule())
        }
    }

    // 녹음 중지 버튼
    private var stopButton: some View {
        Button {
            recorder.stopRecording()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "stop.fill")
                Text("녹음 중지")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.gray700)
            .clipShape(Capsule())
        }
    }

    // 녹음 완료 후 버튼들
    private var completedButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // 재생 버튼
                Button {
                    do {
                        try recorder.playRecording()
                    } catch {
                        errorMessage = "재생에 실패했습니다."
                        showErrorAlert = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("재생")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.gray700)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.gray100)
                    .clipShape(Capsule())
                }

                // 삭제 버튼
                Button {
                    recorder.cancelRecording()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text("삭제")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.gray100)
                    .clipShape(Capsule())
                }
            }

            // 적용 버튼
            Button {
                // 임시 파일을 영구 파일로 복사 (UUID 파일명)
                guard let permanentURL = recorder.savePermanentCopy() else {
                    errorMessage = "파일 저장에 실패했습니다."
                    showErrorAlert = true
                    return
                }
                onApply(permanentURL)
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                    Text("적용")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.main700)
                .clipShape(Capsule())
            }
        }
    }

    private var statusText: String {
        if recorder.isRecording {
            return "녹음 중..."
        } else if recorder.hasRecording() {
            return "녹음 완료!"
        } else {
            return "최대 3초까지 녹음할 수 있습니다"
        }
    }
}

// MARK: - Helpers
extension RecordingSheet {
    /// 시간 포맷 (00.0)
    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d.%d", seconds, tenths)
    }

    /// 권한 체크 후 녹음 시작
    private func startRecordingWithPermission() async {
        let permission = recorder.checkPermission()

        switch permission {
        case .granted:
            startRecording()
        case .denied:
            showPermissionAlert = true
        case .undetermined:
            let granted = await recorder.requestPermission()
            if granted {
                startRecording()
            } else {
                showPermissionAlert = true
            }
        @unknown default:
            showPermissionAlert = true
        }
    }

    /// 녹음 시작
    private func startRecording() {
        do {
            try recorder.startRecording()
        } catch {
            errorMessage = "녹음을 시작할 수 없습니다: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

// MARK: - PreferenceKey
struct RecordingSheetHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 300
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
#Preview {
    RecordingSheet { url in
        print("적용: \(url)")
    }
}
