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
    private var recordingTask: Task<Void, Never>?

    var isRecording = false
    var recordingTime: TimeInterval = 3.0 // 3초
    var recordingURL: URL?
    var audioLevel: Float = 0.0

    // MARK: - Constants
    private let maxRecordingDuration: TimeInterval = 3.0 // 3초

    // MARK: - File Paths
    private var customSoundsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let soundsDir = documentsPath.appendingPathComponent("CustomSounds")

        // 디렉토리가 없으면 생성
        if !FileManager.default.fileExists(atPath: soundsDir.path()) {
            try? FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
        }
        return soundsDir
    }

    // MARK: - Permission
    /// 마이크 권한 요청
    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
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
        audioRecorder?.isMeteringEnabled = true // 오디오 레벨 측정 활성화
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()

        isRecording = true
        recordingTime = maxRecordingDuration // 3:00부터 시작
        recordingURL = url
        audioLevel = 0.0

        // Swift Concurrency 타이머 시작
        startRecordingTimer()
    }

    /// 녹음 중지
    func stopRecording() {
        audioRecorder?.stop()
        recordingTask?.cancel()
        recordingTask = nil
        isRecording = false
        audioLevel = 0.0

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

        // 타이머 초기화 (3초로 리셋)
        recordingTime = maxRecordingDuration
    }

    // MARK: - Timer (Swift Concurrency)
    private func startRecordingTimer() {
        recordingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.recordingTime -= 0.1 // 카운트다운

                    // 오디오 레벨 업데이트
                    self.audioRecorder?.updateMeters()
                    if let averagePower = self.audioRecorder?.averagePower(forChannel: 0) {
                        // averagePower는 -160 ~ 0 범위 (dB)
                        // -50dB ~ 0dB를 0.0 ~ 1.0으로 매핑 (더 민감하게)
                        let minDb: Float = -50.0
                        let maxDb: Float = 0.0

                        // 클램핑 후 정규화
                        let clampedDb = max(minDb, min(maxDb, averagePower))
                        let normalizedLevel = (clampedDb - minDb) / (maxDb - minDb)

                        self.audioLevel = normalizedLevel
                    }

                    // 0초 도달 시 자동 중지
                    if self.recordingTime <= 0 {
                        self.recordingTime = 0
                        self.stopRecording()
                    }
                }
            }
        }
    }

    // MARK: - Playback Preview
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    /// 녹음된 파일 재생 (볼륨 증폭)
    func playRecording() throws {
        guard let url = recordingURL else { return }

        // 오디오 세션 설정 (스피커로 재생)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [])
        try audioSession.setActive(true)

        // 기존 재생 중지
        stopPlayback()

        // AVAudioEngine 설정
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let engine = audioEngine, let player = playerNode else { return }

        engine.attach(player)

        // 오디오 파일 로드
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat

        // 볼륨 증폭 노드 생성 (6배 증폭)
        let volumeNode = AVAudioMixerNode()
        engine.attach(volumeNode)
        volumeNode.volume = 6.0

        // 노드 연결: playerNode -> volumeNode -> engine output
        engine.connect(player, to: volumeNode, format: format)
        engine.connect(volumeNode, to: engine.mainMixerNode, format: format)

        // 엔진 시작
        try engine.start()

        // 오디오 재생
        player.scheduleFile(audioFile, at: nil)
        player.play()
    }

    /// 재생 중지
    func stopPlayback() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }

    // MARK: - File Management
    /// 녹음 파일이 존재하는지 확인
    func hasRecording() -> Bool {
        guard let url = recordingURL else { return false }
        return FileManager.default.fileExists(atPath: url.path())
    }

    /// 임시 녹음 파일을 영구 파일로 복사 (고유한 UUID 파일명)
    func savePermanentCopy() -> URL? {
        guard let tempURL = recordingURL else { return nil }
        guard FileManager.default.fileExists(atPath: tempURL.path()) else { return nil }

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
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        recordingTask?.cancel()
        recordingTask = nil
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("녹음 오류: \(error?.localizedDescription ?? "알 수 없는 오류")")
        stopRecording()
    }
}
