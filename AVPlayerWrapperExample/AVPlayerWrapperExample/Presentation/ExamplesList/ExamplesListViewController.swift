//
//  ExamplesListViewController.swift
//  AVPlayerWrapperExample
//
//  Created by Pavel Moslienko on 03.07.2024.
//

import UIKit
import AVPlayerWrapper
import AVFoundation

final class ExamplesListViewController: UIViewController {
    
    let viewModel = ExamplesListViewModel()
    var audioPlayer: AVAudioPlayer?
    // MARK: - UI components
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.musicPlayer.stop()
    }
}

// MARK: - Module methods
private extension ExamplesListViewController {
    
    func setupUI() {
        self.title = "Examples"
        self.view.backgroundColor = .systemGroupedBackground
        self.navigationController?.navigationBar.barStyle = .default
        self.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
        
        self.view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    
    func handleExample(_ example: ExampleType) {
        
        switch example {
        case .singleLocal:
            if let url = Bundle.main.createFileUrl(forResource: "sos.mp3") {
                viewModel.musicPlayer.setPlaylist([url])
                viewModel.musicPlayer.play()
            }
        case .singleUrl:
            if let url = URL(string: "http://webaudioapi.com/samples/audio-tag/chrono.mp3") {
                viewModel.musicPlayer.setPlaylist([url])
                viewModel.musicPlayer.play()
            }
        case .player:
            let vc = PlaylistViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension ExamplesListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.examples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        
        let example = viewModel.examples[indexPath.row]
        cell.textLabel?.text = example.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let example = viewModel.examples[indexPath.row]
        handleExample(example)
    }
}

// MARK: - UITableViewDataSource
extension ExamplesListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
