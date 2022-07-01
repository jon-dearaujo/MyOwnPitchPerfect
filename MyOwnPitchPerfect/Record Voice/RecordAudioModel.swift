//
//  RecordAudioModel.swift
//  MyOwnPitchPerfect
//
//  Created by Jonathan De Araújo Silva on 18/06/22.
//

import Foundation
import AVFoundation

protocol RecordAudioModelDelegate: AnyObject {
    func initDidComplete(success: Bool, reason: String?)
    func recordDidComplete(success: Bool, reason: String?)
}

struct RecordAudioModel {

    let recordSession: AVAudioSession
    var recorder: AVAudioRecorder?
    weak var delegate: RecordAudioModelDelegate!

    init(delegate: RecordAudioModelDelegate!) {
        self.delegate = delegate
        recordSession = AVAudioSession.sharedInstance()
        let audioFileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("recording.wav")
        do {
            recorder = try AVAudioRecorder(url: audioFileUrl, settings: [:])
            try recordSession.setCategory(.playAndRecord, mode: .default)
            try recordSession.setActive(true)

            recordSession.requestRecordPermission { allowed in
                switch allowed {
                case true:
                    delegate.initDidComplete(success: true, reason: nil)
                    print("Permission to record granted")
                case false:
                    delegate.initDidComplete(success: false, reason: "Permission to record not granted" )
                    print("Permission to record not granted")
                }
            }
        } catch {
            delegate.initDidComplete(success: false, reason: "Could not access audio features")
            print("Error creating RecordAudioModel \(error)")
        }
    }

    func record() {
        recorder?.record()
    }

    func stopRecording() {
        recorder?.stop()
        delegate?.recordDidComplete(success: true, reason: nil)
    }

    var url: URL? {
        recorder?.url
    }
}
