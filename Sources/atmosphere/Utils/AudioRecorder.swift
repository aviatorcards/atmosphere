import AVFoundation
import Foundation
import SwiftUI

@MainActor
class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var permissionGranted = false

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    override init() {
        super.init()
        checkPermission()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            permissionGranted = true
        case .denied, .restricted:
            permissionGranted = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] allowed in
                Task { @MainActor [weak self] in
                    self?.permissionGranted = allowed
                }
            }
        @unknown default:
            break
        }
    }

    func startRecording() {
        guard permissionGranted else { return }

        // macOS doesn't need AVAudioSession setup for basic recording

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording-\(UUID().uuidString).m4a"
        let url = tempDir.appendingPathComponent(fileName)
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Could not start recording: \(error)")
        }
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        return recordingURL
    }

    nonisolated func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder, successfully flag: Bool
    ) {
        Task { @MainActor in
            if !flag {
                // handle failure
            }
        }
    }
}
