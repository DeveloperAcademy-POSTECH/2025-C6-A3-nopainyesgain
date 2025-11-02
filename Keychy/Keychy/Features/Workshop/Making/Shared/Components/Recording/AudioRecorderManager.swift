//
//  AudioRecorderManager.swift
//  Keychy
//
//  음성 녹음 관리 매니저
//

import Foundation
import AVFoundation
import Observation

@Observable
class AudioRecorderManager: NSObject {
    // MARK: - Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?

    var isRecording = false
    var recordingTime: TimeInterval = 0
    var recordingURL: URL?

    // MARK: - Constants
    private let maxRecordingDuration: TimeInterval = 3.0

    // MARK: - File Paths
    private var customSoundsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let soundsDir = documentsPath.appendingPathComponent("CustomSounds")

        // 디렉토리가 없으면 생성
        if !FileManager.default.fileExists(atPath: soundsDir.path) {
            try? FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
        }
        return soundsDir
    }

    // MARK: - Permission
    /// 마이크 권한 요청
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    /// 현재 권한 상태 확인
    func checkPermission() -> AVAudioSession.RecordPermission {
        return AVAudioSession.sharedInstance().recordPermission
    }

    // MARK: - Recording
    /// 녹음 시작
    func startRecording() throws {
        // 이전 녹음이 있으면 정리
        if let existingURL = recordingURL {
            try? FileManager.default.removeItem(at: existingURL)
        }

        // 오디오 세션 설정 (감도 향상)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try audioSession.setActive(true)

        // 입력 설정
        if audioSession.isInputGainSettable {
            try audioSession.setInputGain(1.0) // 최대 감도
        }

        // 녹음 파일 경로 (덮어쓰기 방식)
        let filename = "custom_recording.m4a"
        let url = customSoundsDirectory.appendingPathComponent(filename)

        // 녹음 설정 (고음질 + 높은 비트레이트)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey: 128000, // 128 kbps
            AVLinearPCMBitDepthKey: 16
        ]

        // 녹음기 생성 및 시작
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()

        isRecording = true
        recordingTime = 0
        recordingURL = url

        // 타이머 시작
        startTimer()
    }

    /// 녹음 중지
    func stopRecording() {
        audioRecorder?.stop()
        stopTimer()
        isRecording = false

        // 오디오 세션 비활성화
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    /// 녹음 취소 (파일 삭제)
    func cancelRecording() {
        stopRecording()

        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }

    // MARK: - Timer
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingTime += 0.1

            // 최대 시간 도달 시 자동 중지
            if self.recordingTime >= self.maxRecordingDuration {
                self.stopRecording()
            }
        }
    }

    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Playback Preview
    private var audioPlayer: AVAudioPlayer?

    /// 녹음된 파일 재생
    func playRecording() throws {
        guard let url = recordingURL else { return }

        // 오디오 세션 설정 (스피커로 재생)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [])
        try audioSession.setActive(true)

        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.volume = 1.0
        audioPlayer?.play()
    }

    /// 재생 중지
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    // MARK: - File Management
    /// 녹음 파일이 존재하는지 확인
    func hasRecording() -> Bool {
        guard let url = recordingURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// 임시 녹음 파일을 영구 파일로 복사 (고유한 UUID 파일명)
    func savePermanentCopy() -> URL? {
        guard let tempURL = recordingURL else { return nil }
        guard FileManager.default.fileExists(atPath: tempURL.path) else { return nil }

        // UUID 기반 고유 파일명 생성
        let uniqueFilename = "\(UUID().uuidString).m4a"
        let permanentURL = customSoundsDirectory.appendingPathComponent(uniqueFilename)

        do {
            // 임시 파일을 새 위치로 복사
            try FileManager.default.copyItem(at: tempURL, to: permanentURL)
            return permanentURL
        } catch {
            print("Error copying recording file: \(error.localizedDescription)")
            return nil
        }
    }

    /// 저장된 커스텀 사운드 URL 가져오기 (하위 호환성 - 더 이상 사용 안 함)
    func getSavedRecordingURL() -> URL? {
        let filename = "custom_recording.m4a"
        let url = customSoundsDirectory.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        stopTimer()
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("녹음 오류: \(error?.localizedDescription ?? "알 수 없는 오류")")
        stopRecording()
    }
}
