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

class CorpusLoadViewController: NSViewController, NSPopoverDelegate, EngineInitDelegate {
    
    @IBOutlet weak var procedureDescriptionLabel: NSTextField!
    @IBOutlet weak var currentTaskLabel: NSTextField!
    @IBOutlet weak var elapsedTimeLabel: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var closeButton: NSButtonCell!
    
    var timer: Timer?
    var milliseconds: Double = 0.0
    var totalGramsToIndex: Int = 0
    
    enum InitPhase {
        case phaseIndexingDocuments
        case phaseIndexingGrams
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.closeButton.isEnabled = false
        self.closeButton.isTransparent = true
        self.procedureDescriptionLabel.stringValue = "Indexing Documents"
        
        runTimer()
    }
    
    private func runTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 0.1,
                                          target: self,
                                          selector: (#selector(CorpusLoadViewController.updateTimer)),
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
    
    private func updatePhase(phase: InitPhase) {
        switch phase {
        case .phaseIndexingDocuments:
            self.procedureDescriptionLabel.stringValue = "Indexing Documents"
            
        case .phaseIndexingGrams:
            self.procedureDescriptionLabel.stringValue = "Indexing K-Grams"
        }
    }
    
    private func resetProgressBar(scaledTo value: Int) {
        self.progressBar.doubleValue = 0.0
        self.progressBar.minValue = 0
        self.progressBar.maxValue = Double(value)
    }
    
    private func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return false
    }
    
    internal func onCorpusDocumentIndexingStarted(documentsToIndex: Int) {
        updatePhase(phase: .phaseIndexingDocuments)
        resetProgressBar(scaledTo: documentsToIndex)
    }
    
    internal func onCorpusGramsIndexingStarted(gramsToIndex: Int) {
        self.totalGramsToIndex = gramsToIndex
        updatePhase(phase: .phaseIndexingGrams)
        resetProgressBar(scaledTo: gramsToIndex)
    }
    
    internal func onCorpusIndexedDocument(withFileName fileName: String) {
        self.currentTaskLabel.stringValue = "Indexed file \(fileName)"
        self.progressBar.increment(by: 1.0)
    }
    
    internal func onCorpusIndexedGram(gramNumber: Int) {
        self.currentTaskLabel.stringValue = "Indexed Gram \(gramNumber)/\(self.totalGramsToIndex)"
        self.progressBar.increment(by: 1.0)
    }
    
    internal func onCorpusInitialized(timeElapsed: Double) {
        self.timer?.invalidate()
        self.timer = nil
        self.progressBar.isHidden = true
        
        self.closeButton.isTransparent = false
        self.closeButton.isEnabled = true
    }
    
    @IBAction func closeButtonTUI(_ sender: Any) {
        self.dismiss(nil)
    }
}
