// File: LuxVia/Features/WordRecorder/WordRecorderModule.swift
// Platform: iOS 15+
// Requires: Swift 5.7+, Xcode 14+
// Frameworks: SwiftUI, AVFoundation, Combine
//
// SUMMARY
// Adds a self‑contained feature to record short audio clips for custom words.
// Includes: permission handling, recording, playback, file management, and a SwiftUI UI.
// Integration is additive and isolated in `LuxVia/Features/WordRecorder/`.
//
// HOW TO INTEGRATE (minimal)
// 1) Add this file to your Xcode target (create folder: LuxVia/Features/WordRecorder/).
// 2) Update Info.plist with:
//    Key: Privacy - Microphone Usage Description (NSMicrophoneUsageDescription)
//    Value: "This app records your voice to capture custom words."
// 3) Present `WordRecorderView()` from your navigation flow (SwiftUI).
//    If the app is UIKit, embed with `UIHostingController(rootView: WordRecorderView())`.
// 4) Build & run on a real device (simulator has no mic input).
//
// DESIGN NOTES
// - Files saved under Documents/Recordings/Words as m4a (AAC 44.1kHz mono).
// - Each filename encodes the sanitized word + timestamp for uniqueness.
// - Minimal inline comments; documentation explains the "why".

import SwiftUI
import AVFoundation
import Combine

// MARK: - Compatibility Modifiers


// MARK: - Compatibility Modifiers

struct TintModifier: ViewModifier {
    let isRecording: Bool
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content.tint(isRecording ? .red : .accentColor)
        } else {
            content.accentColor(isRecording ? .red : .accentColor)
        }
    }
}

struct TaskModifier: ViewModifier {
    let action: () async -> Void
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content.task { await action() }
        } else {
            content
        }
    }
}

struct AlertModifier: ViewModifier {
    @Binding var showAlert: Bool
    var alertMessage: String
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content.alert("Recording", isPresented: $showAlert, actions: { Button("OK", role: .cancel) {} }, message: { Text(alertMessage) })
        } else {
            content
        }
    }
}

// MARK: - Domain Model

public struct WordRecording: Identifiable, Hashable, Codable {
    public let id: UUID
    public let word: String
    public let url: URL
    public let createdAt: Date
    public let duration: TimeInterval
}

// MARK: - Errors

enum RecordingError: LocalizedError {
    case permissionDenied
    case cannotConfigureSession(Error?)
    case cannotCreateDirectory(Error)
    case cannotStartRecording(Error?)
    case noActiveRecorder
    case fileMissing

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Microphone permission denied. Enable it in Settings > Privacy > Microphone."
        case .cannotConfigureSession(let err): return "Failed to configure audio session.\n\(err?.localizedDescription ?? "Unknown error")."
        case .cannotCreateDirectory(let err): return "Failed to create recordings directory: \(err.localizedDescription)."
        case .cannotStartRecording(let err): return "Failed to start recording: \(err?.localizedDescription ?? "Unknown error")."
        case .noActiveRecorder: return "No active recording."
        case .fileMissing: return "Recorded file missing."
        }
    }
}

// MARK: - File System Helpers

struct WordRecordingsStore {
    let baseDirectory: URL

    init(fileManager: FileManager = .default) {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        baseDirectory = docs.appendingPathComponent("Recordings/Words", isDirectory: true)
    }

    func ensureDirectoryExists() throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: baseDirectory.path) {
            do { try fm.createDirectory(at: baseDirectory, withIntermediateDirectories: true) }
            catch { throw RecordingError.cannotCreateDirectory(error) }
        }
    }

    func sanitizeWord(_ word: String) -> String {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "word"
        guard !trimmed.isEmpty else { return fallback }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let mapped = trimmed.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let collapsed = String(mapped).replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
        return collapsed.lowercased()
    }

    func makeFileURL(for word: String, at date: Date = Date()) -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let stamp = formatter.string(from: date).replacingOccurrences(of: ":", with: "-")
        let name = sanitizeWord(word)
        return baseDirectory.appendingPathComponent("\(name)_\(stamp).m4a", isDirectory: false)
    }

    func listRecordings() -> [WordRecording] {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: [.skipsHiddenFiles]) else { return [] }
        return items.compactMap { url in
            let word = url.deletingPathExtension().lastPathComponent.split(separator: "_").first.map(String.init) ?? "word"
            let created = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
            let asset = AVURLAsset(url: url)
            let duration = CMTimeGetSeconds(asset.duration)
            return WordRecording(id: UUID(), word: word, url: url, createdAt: created, duration: duration)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    func delete(_ recording: WordRecording) throws {
        try FileManager.default.removeItem(at: recording.url)
    }
}

// MARK: - Audio Recorder

final class WordAudioRecorder: NSObject, ObservableObject {
    @Published private(set) var isRecording: Bool = false {
        didSet {
            print("DEBUG: isRecording changed to", isRecording)
        }
    }
    @Published private(set) var currentWord: String? = nil
    @Published var lastError: RecordingError? = nil

    private var recorder: AVAudioRecorder?
    private let store = WordRecordingsStore()

    override init() {
        super.init()
        print("DEBUG: WordAudioRecorder initialized")
    }

    func requestPermission() async throws {
        let granted: Bool = await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in cont.resume(returning: allowed) }
        }
        if !granted { throw RecordingError.permissionDenied }
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch { throw RecordingError.cannotConfigureSession(error) }
    }

    func startRecording(for word: String) throws -> URL {
        try store.ensureDirectoryExists()
        try configureSession()
        let url = store.makeFileURL(for: word)
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            guard recorder?.record() == true else { throw RecordingError.cannotStartRecording(nil) }
            currentWord = word
            isRecording = true
            print("DEBUG: startRecording called, isRecording set to true")
            lastError = nil
            return url
        } catch {
            throw RecordingError.cannotStartRecording(error)
        }
    }

    @discardableResult
    func stopRecording() throws -> URL {
        guard let recorder = recorder, isRecording else { throw RecordingError.noActiveRecorder }
        recorder.stop()
    isRecording = false
    print("DEBUG: stopRecording called, isRecording set to false")
        let url = recorder.url
        self.recorder = nil
        return url
    }

    func cancelRecordingAndDelete() {
        guard let recorder = recorder else { return }
        isRecording = false
        recorder.stop()
        try? FileManager.default.removeItem(at: recorder.url)
        self.recorder = nil
    }
}

extension WordAudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        lastError = .cannotStartRecording(error)
    }
}

// MARK: - Audio Player (simple)

final class WordAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentURL: URL? = nil

    private var player: AVAudioPlayer?

    func play(url: URL) {
        if player?.url == url, isPlaying { stop() ; return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            isPlaying = player?.play() ?? false
            currentURL = url
        } catch {
            isPlaying = false
            currentURL = nil
        }
    }

    func stop() {
        player?.stop()
        isPlaying = false
        currentURL = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentURL = nil
    }
}

// MARK: - View Model

@MainActor
final class WordRecorderViewModel: ObservableObject {
    @Published var inputWord: String = ""
    @Published private(set) var recordings: [WordRecording] = []
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let recorder = WordAudioRecorder()
    let player = WordAudioPlayer()
    private let store = WordRecordingsStore()

    init() {
        refresh()
    }

    func refresh() {
        recordings = store.listRecordings()
    }

    func begin() async {
        do { try await recorder.requestPermission() }
        catch {
            alertMessage = (error as? RecordingError)?.localizedDescription ?? error.localizedDescription
            showAlert = true
        }
    }

    func startRecording() {
        Task { @MainActor in
            do {
                _ = try recorder.startRecording(for: inputWord.isEmpty ? "word" : inputWord)
            } catch {
                print("DEBUG: startRecording error:", error)
                alertMessage = (error as? RecordingError)?.localizedDescription ?? error.localizedDescription
                showAlert = true
            }
        }
    }

    func stopRecording() {
        Task { @MainActor in
            do {
                _ = try recorder.stopRecording()
                refresh()
            } catch {
                print("DEBUG: stopRecording error:", error)
                alertMessage = (error as? RecordingError)?.localizedDescription ?? error.localizedDescription
                showAlert = true
            }
        }
    }

    func delete(_ recording: WordRecording) {
        do { try store.delete(recording); refresh() }
        catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

// MARK: - SwiftUI UI

public struct WordRecorderView: View {
    @StateObject private var model = WordRecorderViewModel()
    @ObservedObject private var recorder: WordAudioRecorder

    public init() {
        let vm = WordRecorderViewModel()
        _model = StateObject(wrappedValue: vm)
        recorder = vm.recorder
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack {
                    TextField("Enter name", text: $model.inputWord)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    RecordButton(isRecording: recorder.isRecording) {
                        print("DEBUG: RecordButton tapped, isRecording:", recorder.isRecording)
                        if recorder.isRecording { model.stopRecording() }
                        else { model.startRecording() }
                    }
                    .accessibilityLabel(recorder.isRecording ? "Stop recording" : "Start recording")
                }
                .padding(.horizontal)

                List {
                    if model.recordings.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No recordings yet").font(.headline)
                            if #available(iOS 17, *) {
                                Text("Type a word, tap Record, then Stop.").font(.caption).foregroundStyle(.secondary)
                            } else {
                                Text("Type a word, tap Record, then Stop.").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                        ForEach(model.recordings) { rec in
                            RecordingRow(
                                recording: rec,
                                isPlaying: isPlaying(for: rec),
                                playAction: { play(rec) },
                                deleteAction: { delete(rec) },
                                addToServiceAction: { addToService(rec) }
                            )
                        }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Record Audio")
            .modifier(TaskModifier { await model.begin() })
            .modifier(AlertModifier(showAlert: $model.showAlert, alertMessage: model.alertMessage))
        }
    }
    // Helper functions to break up complex expressions
    private func isPlaying(for rec: WordRecording) -> Bool {
        model.player.currentURL == rec.url && model.player.isPlaying
    }
    private func play(_ rec: WordRecording) {
        model.player.play(url: rec.url)
    }
    private func delete(_ rec: WordRecording) {
        model.delete(rec)
    }
    private func addToService(_ rec: WordRecording) {
        let serviceItem = ServiceItem(
            type: .customReading,
            title: rec.word,
            subtitle: nil,
            fileName: rec.url.lastPathComponent,
            customText: nil,
            uid: nil
        )
        ServiceOrderManager.shared.add(serviceItem)
    }
}

private struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                        .font(.system(size: 36))
                        .foregroundColor(isRecording ? .red : .accentColor)
                    Text(isRecording ? "Stop Recording" : "Record")
                        .font(.headline)
                        .foregroundColor(isRecording ? .red : .accentColor)
                }
            }
            .modifier(TintModifier(isRecording: isRecording))
    }
}

private struct RecordingRow: View {
    let recording: WordRecording
    let isPlaying: Bool
    let playAction: () -> Void
    let deleteAction: () -> Void
    let addToServiceAction: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.word).font(.headline)
                if #available(iOS 17, *) {
                    Text("\(Self.format(recording.duration))  ·  \(recording.createdAt, style: .date) \(recording.createdAt, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(Self.format(recording.duration))  ·  \(recording.createdAt, style: .date) \(recording.createdAt, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(action: playAction) {
                Image(systemName: isPlaying ? "pause.circle" : "play.circle")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            Button(action: addToServiceAction) {
                Image(systemName: "plus.circle")
                Text("Add to Service")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            if #available(iOS 15.0, *) {
                Button(role: .destructive, action: deleteAction) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            } else {
                // Fallback on earlier versions
            }
        }
    }

    static func format(_ secs: TimeInterval) -> String {
        guard secs.isFinite && secs >= 0 else { return "0:00" }
        let m = Int(secs) / 60
        let s = Int(secs) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Previews

#if DEBUG
struct WordRecorderView_Previews: PreviewProvider {
    static var previews: some View {
        WordRecorderView()
    }
}
#endif

// MARK: - Minimal Unit Tests (paste into your test target if desired)
/*
// File: LuxViaTests/WordRecordingsStoreTests.swift
import XCTest
@testable import LuxVia

final class WordRecordingsStoreTests: XCTestCase {
    func testSanitize() {
        let s = WordRecordingsStore()
        XCTAssertEqual(s.sanitizeWord(" Hello World! "), "hello-world-")
        XCTAssertEqual(s.sanitizeWord(""), "word")
    }
}
*/

