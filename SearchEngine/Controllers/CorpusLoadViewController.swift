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

class CorpusLoadViewController: NSViewController, NSPopoverDelegate, EngineInitDelegate  {
    
    @IBOutlet weak var procedureDescriptionLabel: NSTextField!
    @IBOutlet weak var currentTaskLabel: NSTextField!
    @IBOutlet weak var elapsedTimeLabel: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    var timer = Timer()
    var milliseconds: Double = 0.0
    var totalGramsToIndex: Int = 0
    
    enum InitPhase {
        case PhaseIndexingDocuments
        case PhaseIndexingGrams
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.procedureDescriptionLabel.stringValue = "Indexing Documents"
        
        runTimer()
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,   selector: (#selector(CorpusLoadViewController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        self.milliseconds += 0.1
        self.elapsedTimeLabel.stringValue = stringFromTimeInterval(interval: TimeInterval(milliseconds)) as String
    }
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let ti = NSInteger(interval)
//        let ms = Int((interval % 1) * 1000)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return String(format: "Elapsed time: %0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }
    
    func updatePhase(phase: InitPhase) -> Void {
        switch phase {
        case .PhaseIndexingDocuments:
            self.procedureDescriptionLabel.stringValue = "Indexing Documents"
            break
            
        case .PhaseIndexingGrams:
            self.procedureDescriptionLabel.stringValue = "Indexing K-Grams"
            break
        }
    }
    
    func resetProgressBar(scaledTo value: Int) -> Void {
        self.progressBar.doubleValue = 0.0
        self.progressBar.minValue = 0
        self.progressBar.maxValue = Double(value)
    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return false
    }
    
    func onCorpusDocumentIndexingStarted(documentsToIndex: Int) {
        updatePhase(phase: .PhaseIndexingDocuments)
        resetProgressBar(scaledTo: documentsToIndex)
    }
    
    func onCorpusGramsIndexingStarted(gramsToIndex: Int) {
        self.totalGramsToIndex = gramsToIndex
        updatePhase(phase: .PhaseIndexingGrams)
        resetProgressBar(scaledTo: gramsToIndex)
    }
    
    func onCorpusIndexedDocument(withFileName fileName: String) {
        self.currentTaskLabel.stringValue = "Indexed file \(fileName)"
        self.progressBar.increment(by: 1.0)
    }
    
    func onCorpusIndexedGram(gramNumber: Int) {
        self.currentTaskLabel.stringValue = "Indexed Gran \(gramNumber)/\(self.totalGramsToIndex)"
        self.progressBar.increment(by: 1.0)
    }
    
    func onCorpusInitialized(timeElapsed: Double) {
        self.dismiss(nil)
    }
}
