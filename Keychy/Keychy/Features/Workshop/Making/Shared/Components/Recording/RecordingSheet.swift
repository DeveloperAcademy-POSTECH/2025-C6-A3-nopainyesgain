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

    let onApply: (URL) -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // 상단 닫기 버튼
            HStack(spacing: 0) {
                deleteButton
                    .padding(.trailing, 15)
                replayButton
                Spacer()
                completedButton
            }
            .padding(.top, 30)
            .padding(.horizontal, 20)
            
            Spacer()
            
            Text("음성 메모")
                .typography(.suit17B)
            startButton
                .padding(.top, 24)
            recordingTime
                .padding(.top, )
            
            Spacer()
        }
        .background(Color.white100)
        .presentationBackground(Color.white100)
        .presentationDetents([.height(300)])
        .presentationBackgroundInteraction(.disabled)
        
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
    // 녹음파일 삭제 버튼
    private var deleteButton: some View {
        Button {
            recorder.cancelRecording()
        } label: {
            HStack(spacing: 4) {
                if recorder.hasRecording() {
                    Image("recDeleteFill")
                } else {
                    Image("recDelete")
                }
                
                Text("삭제")
                    .typography(.suit14M)
                    .foregroundStyle(recorder.hasRecording() ? .gray600 : .gray200)
            }
        }
        .buttonStyle(.plain)
        .disabled(!recorder.hasRecording()) // 녹음 파일 없으면 비활성화
    }
    
    // 녹음 재생 버튼
    private var replayButton: some View {
        Button {
            do {
                try recorder.playRecording()
            } catch {
                errorMessage = "재생에 실패했습니다."
                showErrorAlert = true
            }
        } label: {
            HStack(spacing: 4) {
                if recorder.hasRecording() && !recorder.isRecording {
                    Image("replayFill")
                } else {
                    Image("replay")
                }
                Text("재생")
                    .typography(.suit14M)
            }
            .foregroundStyle(recorder.hasRecording() && !recorder.isRecording ? .gray600 : .gray200)
        }
        .buttonStyle(.plain)
        .disabled(!recorder.hasRecording() || recorder.isRecording)
    }
    
    private var dismissButton: some View {
        Button {
            if recorder.isRecording {
                recorder.cancelRecording()
            } else {
                dismiss()
            }
        } label: {
            Image("dismiss")
                .foregroundStyle(.primary)
        }
    }
    
    // 녹음 완료 버튼, 닫기
    private var completedButton: some View {
        Button {
            // 녹음 파일 존재 확인
            guard recorder.hasRecording() else {
                errorMessage = "녹음된 파일이 없습니다."
                showErrorAlert = true
                return
            }

            // 임시 파일을 영구 파일로 복사 (UUID 파일명)
            guard let permanentURL = recorder.savePermanentCopy() else {
                errorMessage = "파일 저장에 실패했습니다."
                showErrorAlert = true
                return
            }

            onApply(permanentURL)
            dismiss()
        } label: {
            Text("저장")
                .typography(.suit17M)
                .foregroundStyle(recorder.hasRecording() && !recorder.isRecording ? .gray500 : .gray200)
        }
        .disabled(!recorder.hasRecording() || recorder.isRecording) // 녹음 중이거나 파일 없으면 비활성화
    }
    
    @ViewBuilder
    private var recordingTime: some View {
        VStack(spacing: 20) {
            // 타이머 표시
            Text(formatTime(recorder.recordingTime))
                .typography(.suit15M25)
                .foregroundStyle(.gray300)
                .monospacedDigit()
        }
    }
    
    // 녹음 시작/중지 버튼 (토글)
    private var startButton: some View {
        ZStack {
            // 녹음 중일 때 오디오 레벨 시각화 (물결 효과 - 맨 뒤, overlay로 분리)
            if recorder.isRecording {
                // 외곽 물결 (더 크게)
                Circle()
                    .fill(Color.main500.opacity(0.15))
                    .frame(
                        width: 55 + CGFloat(recorder.audioLevel) * 50,
                        height: 55 + CGFloat(recorder.audioLevel) * 50
                    )
                    .animation(.easeOut(duration: 0.15), value: recorder.audioLevel)

                // 중간 물결
                Circle()
                    .fill(Color.main500.opacity(0.25))
                    .frame(
                        width: 55 + CGFloat(recorder.audioLevel) * 30,
                        height: 55 + CGFloat(recorder.audioLevel) * 30
                    )
                    .animation(.easeOut(duration: 0.12), value: recorder.audioLevel)
            }

            // 버튼 본체 (고정 크기)
            Button(action: {
                if recorder.isRecording {
                    // 녹음 중 → 중지
                    recorder.stopRecording()
                } else {
                    // 녹음 전 → 시작
                    Task {
                        await startRecordingWithPermission()
                    }
                }
            }) {
                ZStack {
                    // 배경 원
                    Circle()
                        .fill(recorder.isRecording ? Color.white100 : Color.main500)
                        .frame(width: 55, height: 55)

                    // 녹음 중일 때 stroke
                    if recorder.isRecording {
                        Circle()
                            .strokeBorder(Color.main500, lineWidth: 3)
                            .frame(width: 55, height: 55)
                    }

                    // 아이콘
                    Image(recorder.isRecording ? "recordingFill" : "recording")
                        .foregroundStyle(recorder.isRecording ? .main500 : .white100)
                }
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .frame(width: 105, height: 105) // 최대 크기로 고정 (55 + 50)
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
    /// 시간 포맷 (3:00)
    private func formatTime(_ time: TimeInterval) -> String {
        let wholeSeconds = Int(time)
        let hundredths = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d", wholeSeconds, hundredths)
    }
    
    /// 권한 체크 후 녹음 시작
    private func startRecordingWithPermission() async {
        let granted = await recorder.requestPermission()
        
        if granted {
            startRecording()
        } else {
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
