//
//  AudioPlayer.swift
//  CameraRollSounds
//
//  Audio playback for generated sounds
//

import AVFoundation
import Foundation

@MainActor
class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var error: String?

    private var player: AVPlayer?
    private var playerObserver: Any?

    func play(url: URL) {
        stop()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            self.error = "Could not configure audio session"
            return
        }

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Observe when playback ends
        playerObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isPlaying = false
            }
        }

        player?.play()
        isPlaying = true
        error = nil
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false

        if let observer = playerObserver {
            NotificationCenter.default.removeObserver(observer)
            playerObserver = nil
        }
    }

    func togglePlayback() {
        if isPlaying {
            stop()
        } else if let player = player {
            player.seek(to: .zero)
            player.play()
            isPlaying = true
        }
    }
}
