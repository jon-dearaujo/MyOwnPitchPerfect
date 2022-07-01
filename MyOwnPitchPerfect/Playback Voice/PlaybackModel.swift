//
//  PlaybackModel.swift
//  MyOwnPitchPerfect
//
//  Created by Jonathan De Araújo Silva on 25/06/22.
//

import Foundation
import AVFoundation

protocol PlaybackModelDelegate: AnyObject {
    func showAlert(_ title: String, message: String)
    func configureUI(_ playState: PlaybackModel.PlayingState)
}

class PlaybackModel {
    var recordedAudioURL: URL!
    var delegate: PlaybackModelDelegate!
    var audioFile: AVAudioFile!
    var audioEngine: AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    var stopTimer: Timer!

    // MARK: Alerts

    // MARK: PlayingState (raw values correspond to sender tags)

    enum PlayingState { case playing, notPlaying }

    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }


    // MARK: Audio Functions

    init(delegate: PlaybackModelDelegate, recordedAudioURL: URL) {
        self.delegate = delegate
        self.recordedAudioURL = recordedAudioURL
        // initialize (recording) audio file
        do {
            audioFile = try AVAudioFile(forReading: recordedAudioURL as URL)
        } catch {
            delegate.showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }

    func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        do {
            // initialize audio engine components
            audioEngine = AVAudioEngine()

            // node for playing audio
            audioPlayerNode = AVAudioPlayerNode()
            audioEngine.attach(audioPlayerNode)

            // node for adjusting rate/pitch
            let changeRatePitchNode = AVAudioUnitTimePitch()
            if let pitch = pitch {
                changeRatePitchNode.pitch = pitch
            }
            if let rate = rate {
                changeRatePitchNode.rate = rate
            }
            audioEngine.attach(changeRatePitchNode)

            // node for echo
            let echoNode = AVAudioUnitDistortion()
            echoNode.loadFactoryPreset(.multiEcho1)
            audioEngine.attach(echoNode)

            // node for reverb
            let reverbNode = AVAudioUnitReverb()
            reverbNode.loadFactoryPreset(.cathedral)
             reverbNode.wetDryMix = 50
            audioEngine.attach(reverbNode)

            // connect nodes
            if echo == true && reverb == true {
                connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
            } else if echo == true {
                connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
            } else if reverb == true {
                connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
            } else {
                connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
            }

            // schedule to play and start the engine!
            audioPlayerNode.stop()
            audioPlayerNode.scheduleFile(audioFile, at: nil) {

                var delayInSeconds: Double = 0

                if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {

                    if let rate = rate {
                        delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                    } else {
                        delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                    }
                }

                // schedule a stop timer for when audio finishes playing
                self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(self.stopAudio), userInfo: nil, repeats: false)
                RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
            }

            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            try audioEngine.start()
        } catch {
            delegate.showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }

        // play the recording!
        audioPlayerNode.play()
    }

    @objc func stopAudio() {
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }

        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }

        delegate.configureUI(.notPlaying)

        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }

    // MARK: Connect List of Audio Nodes

    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: nil)
        }
    }
}
