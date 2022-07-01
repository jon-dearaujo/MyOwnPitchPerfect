//
//  RecordViewController.swift
//  MyOwnPitchPerfect
//
//  Created by Jonathan De Araújo Silva on 07/06/22.
//

import UIKit

class RecordViewController: UIViewController {

    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var stopRecordingButton: UIButton!
    @IBOutlet weak var buttonsStackView: UIStackView!
    
    var recordAudioModel: RecordAudioModel!
    var spinner: UIActivityIndicatorView!

    enum UIState {
        case initialLoading, recording, notRecording, blocked
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        spinner = UIActivityIndicatorView(frame: view.frame)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        updateUI(.initialLoading)

        recordAudioModel = RecordAudioModel(delegate: self)
    }

    @IBAction func recordButtonPressed(_ sender: Any) {
        updateUI(.recording)
        recordAudioModel.record()
    }

    @IBAction func stopRecordingButtonPressed(_ sender: Any) {
        updateUI(.notRecording)
        recordAudioModel.stopRecording()
        performSegue(withIdentifier: "SoundPlayback", sender: recordAudioModel.url)
    }

    private func updateUI(_ state: UIState) {
        switch(state) {
        case .initialLoading:
            spinner.startAnimating()
            recordButton.isEnabled = false
            stopRecordingButton.isEnabled = false
            buttonsStackView.alpha = 0.25
        case .recording:
            spinner.stopAnimating()
            buttonsStackView.alpha = 1
            UIView.animate(withDuration: 0.25, delay: 0, animations: {
                self.recordingLabel.alpha = 0
            })
            recordButton.isEnabled = false
            recordingLabel.text = "Recording in progress..."
            stopRecordingButton.isEnabled = true
            UIView.animate(withDuration: 0.25, delay: 0, animations: {
                self.recordingLabel.alpha = 1
                self.recordButton.alpha = 0.5
                self.stopRecordingButton.alpha = 1
            })
        case .notRecording:
            spinner.stopAnimating()
            buttonsStackView.alpha = 1
            recordButton.isEnabled = true
            UIView.animate(withDuration: 0.5, delay: 0, animations: {
                self.recordingLabel.alpha = 0
            })
            recordingLabel.text = "Tap to record"
            UIView.animate(withDuration: 0.25, delay: 0, animations: {
                self.recordingLabel.alpha = 1
                self.recordButton.alpha = 1
                self.stopRecordingButton.alpha = 0.5
            })
        case .blocked:
            spinner.stopAnimating()
            buttonsStackView.alpha = 1
            recordButton.isEnabled = false
            stopRecordingButton.isEnabled = false
            recordingLabel.numberOfLines = 0
            recordingLabel.textAlignment = .center
            recordingLabel.text = "Can't access microphone.\n Please grant access on Preferences."
            UIView.animate(withDuration: 0.25, delay: 0, animations: {
                self.recordingLabel.alpha = 1
                self.recordButton.alpha = 0.5
                self.stopRecordingButton.alpha = 0.5
            })
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SoundPlayback" {
            (segue.destination as! PlaybackViewController).playbackModel = PlaybackModel(
                delegate: segue.destination as! PlaybackModelDelegate,
                recordedAudioURL: sender as! URL)
        }
    }
}

extension RecordViewController: RecordAudioModelDelegate {
    func initDidComplete(success: Bool, reason: String?) {
        DispatchQueue.main.async {
            if success {
                self.updateUI(.notRecording)
            } else {
                self.updateUI(.blocked)
            }
        }
    }

    func recordDidComplete(success: Bool, reason: String?) {
        DispatchQueue.main.async {
            self.updateUI(.notRecording)
        }
    }
}
