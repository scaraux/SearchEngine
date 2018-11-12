//
//  CorpusLoadViewController.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Cocoa

extension TimeInterval {
    func format() -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second, .nanosecond]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1
        return formatter.string(from: self)
    }
}

class CorpusLoadViewController: NSViewController, NSPopoverDelegate {

    @IBOutlet weak var procedureDescriptionLabel: NSTextField!
    @IBOutlet weak var currentTaskLabel: NSTextField!
    @IBOutlet weak var elapsedTimeLabel: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var closeButton: NSButtonCell!
    
    var timer: Timer?
    var milliseconds: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.timer = nil
        self.closeButton.isEnabled = false
        self.closeButton.isTransparent = true
        self.currentTaskLabel.stringValue = ""
        self.procedureDescriptionLabel.stringValue = ""
    }
    
    private func runTimer() {
        guard self.timer == nil else { return }
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.1,
                                          target: self,
                                          selector: #selector(updateTimer),
                                          userInfo: nil,
                                          repeats: true)
    }
    
    private func killTimer() {
        self.timer = nil
    }
    
    @objc func updateTimer() {
        self.milliseconds += 0.1
        self.elapsedTimeLabel.stringValue = stringFromTimeInterval(interval: TimeInterval(milliseconds)) as String
    }
    
    private func stringFromTimeInterval(interval: TimeInterval) -> String {
        let ti = NSInteger(interval)
//        let ms = Int((interval % 1) * 1000)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return String(format: "Elapsed time: %0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }
    
    private func resetProgressBar(scaledTo value: Int) {
        self.progressBar.doubleValue = 0.0
        self.progressBar.minValue = 0
        self.progressBar.maxValue = Double(value)
    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return false
    }
}

extension CorpusLoadViewController: CreateEnvironmentDelegate {
    
    func onInitializationPhaseChanged(phase: CreateEnvironmentPhase, withTotalCount count: Int) {
        switch phase {
        case .phaseIndexingDocuments:
            runTimer()
            resetProgressBar(scaledTo: count)
            self.procedureDescriptionLabel.stringValue = "Indexing Documents"
            
        case .phaseIndexingGrams:
            resetProgressBar(scaledTo: count)
            self.procedureDescriptionLabel.stringValue = "Indexing K-Grams"
            
        case .phaseWritingIndex:
            self.procedureDescriptionLabel.stringValue = "Writing Index to Disk"
            
        case .terminated:
            self.timer?.invalidate()
            self.progressBar.isHidden = true
            self.closeButton.isTransparent = false
            self.closeButton.isEnabled = true
        }
    }

    func onIndexingDocument(withFileName fileName: String, documentNb: Int, totalDocuments: Int) {
        self.currentTaskLabel.stringValue = "Indexing file \(fileName)"
        self.progressBar.increment(by: 1.0)
    }

    func onIndexingGrams(forType type: String, typeNb: Int, totalTypes: Int) {
        self.currentTaskLabel.stringValue = "Indexing Gram (\(typeNb)/\(totalTypes))"
        self.progressBar.increment(by: 1.0)
    }
}

extension CorpusLoadViewController: LoadEnvironmentDelegate {
    
    func onLoadingPhaseChanged(phase: LoadEnvironmentPhase, withTotalCount count: Int) {
        switch phase {
        case .phaseLoadingGrams:
            runTimer()
            resetProgressBar(scaledTo: count)
            self.procedureDescriptionLabel.stringValue = "Loading Grams"
    
        case .terminated:
            self.timer?.invalidate()
            self.progressBar.isHidden = true
            self.closeButton.isTransparent = false
            self.closeButton.isEnabled = true
        }
    }
    
    func onLoadingTypes(forGram: String, gramNb: Int, totalGrams: Int) {
        self.currentTaskLabel.stringValue = "Indexing Gram (\(gramNb)/\(totalGrams))"
        self.progressBar.increment(by: 1.0)
    }
}

extension CorpusLoadViewController {
    @IBAction func closeButtonTUI(_ sender: Any) {
        self.dismiss(nil)
    }
}
