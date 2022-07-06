//
//  PlaybackViewController.swift
//  MyOwnPitchPerfect
//
//  Created by Jonathan De Araújo Silva on 25/06/22.
//

import UIKit

class PlaybackViewController: UIViewController {

    var playbackModel: PlaybackModel!
    let BUTTON_SIZE = 120.0
    var buttons: [String: UIButton] = [:]
    var wideConstraints: [NSLayoutConstraint]!
    var narrowConstraints: [NSLayoutConstraint]!

    enum Buttons: String, CaseIterable {
        case fast, slow, high, low, echo, reverb
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        let containerStackView = UIStackView(frame: view.frame)
        view.addSubview(containerStackView)
        containerStackView.axis = .vertical
        containerStackView.alignment = .center
        containerStackView.distribution = .fillEqually
        containerStackView.translatesAutoresizingMaskIntoConstraints = false

        containerStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true

        let stopButton = UIButton(frame: containerStackView.frame)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stopButton)
        stopButton.widthAnchor
            .constraint(equalToConstant: BUTTON_SIZE).isActive = true
        stopButton.heightAnchor
            .constraint(equalToConstant: BUTTON_SIZE).isActive = true

        stopButton.setImage(UIImage(named: "Stop"), for: .normal)
        stopButton.addTarget(self, action: #selector(stopButtonClicked), for: .touchUpInside)


        narrowConstraints = [
            containerStackView.topAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8.0),
            containerStackView.leadingAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stopButton.topAnchor
                .constraint(equalTo: containerStackView.bottomAnchor, constant: 8.0),
            stopButton.centerXAnchor
                .constraint(equalTo: view.centerXAnchor),
            stopButton.bottomAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20.0),
        ]

        wideConstraints = [
            stopButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20.0),
            stopButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            containerStackView.topAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4.0),
            containerStackView.leadingAnchor.constraint(equalTo: stopButton.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 4.0),
        ]

        var horizontalStackView: UIStackView?
        Buttons.allCases.enumerated().forEach { (index, buttonName) in
            if index % 2 == 0 {
                horizontalStackView = UIStackView(frame: containerStackView.frame)
                containerStackView.addArrangedSubview(horizontalStackView!)
                horizontalStackView!.axis = .horizontal
                horizontalStackView!.alignment = .center
                horizontalStackView!.distribution = .fillEqually
                horizontalStackView!.spacing = 24
            }

            let button = UIButton(frame: horizontalStackView!.frame)
            horizontalStackView!.addArrangedSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.titleLabel?.text = buttonName.rawValue
            button.contentHorizontalAlignment = .fill
            button.contentVerticalAlignment = .fill
            button.setImage(UIImage(named: buttonName.rawValue.capitalized), for: .normal)
            button.addTarget(self, action: #selector(playbackButtonClicked), for: .touchUpInside)
            buttons[buttonName.rawValue] = button

            narrowConstraints.append(button.widthAnchor.constraint(equalToConstant: BUTTON_SIZE))
            narrowConstraints.append(button.heightAnchor.constraint(equalToConstant: BUTTON_SIZE))
            wideConstraints.append(button.widthAnchor.constraint(lessThanOrEqualToConstant: BUTTON_SIZE))
            wideConstraints.append(button.heightAnchor.constraint(lessThanOrEqualToConstant: BUTTON_SIZE))
        }

        if view.frame.width > view.frame.height {
            NSLayoutConstraint.deactivate(narrowConstraints)
            NSLayoutConstraint.activate(wideConstraints)
        } else {
            NSLayoutConstraint.deactivate(wideConstraints)
            NSLayoutConstraint.activate(narrowConstraints)
        }

    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate {_ in
            if self.view.frame.width > self.view.frame.height {
                NSLayoutConstraint.deactivate(self.narrowConstraints)
                NSLayoutConstraint.activate(self.wideConstraints)
            } else {
                NSLayoutConstraint.deactivate(self.wideConstraints)
                NSLayoutConstraint.activate(self.narrowConstraints)
            }
        }
    }

    @objc func playbackButtonClicked(sender: UIButton!) {
        configureUI(.playing)
        switch(Buttons(rawValue: sender.titleLabel!.text!)!) {
        case .slow:
            playbackModel.playSound(rate: 0.5)
        case .fast:
            playbackModel.playSound(rate: 1.5)
        case .high:
            playbackModel.playSound(pitch: 1000)
        case .low:
            playbackModel.playSound(pitch: -1000)
        case .echo:
            playbackModel.playSound(echo: true)
        case .reverb:
            playbackModel.playSound(reverb: true)
        }
    }

    @objc func stopButtonClicked(sender: UIButton!) {
        playbackModel.stopAudio()
    }
}

extension PlaybackViewController: PlaybackModelDelegate {
    func configureUI(_ playState: PlaybackModel.PlayingState) {
        switch(playState) {
        case .playing:
            setPlayButtonsEnabled(false)
        case .notPlaying:
            setPlayButtonsEnabled(true)
        }
    }

    func setPlayButtonsEnabled(_ enabled: Bool) {
        buttons.forEach { buttonEntry in
            buttonEntry.value.isEnabled = enabled
        }
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: PlaybackModel.Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
