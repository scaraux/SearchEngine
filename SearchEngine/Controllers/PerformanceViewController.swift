//
//  PerformanceViewController.swift
//  SearchEngine
//
//  Created by Oscar Götting on 12/12/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Cocoa

class PerformanceViewController: NSViewController, NSPopoverDelegate {
    
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var currentQueryLabel: NSTextField!
    @IBOutlet weak var queryExecutedLabel: NSTextField!
    @IBOutlet weak var MAPLabel: NSTextField!
    @IBOutlet weak var MRPLabel: NSTextField!
    @IBOutlet weak var timeElapsedLabel: NSTextField!
    @IBOutlet weak var throughputLabel: NSTextField!
    @IBOutlet weak var avgAccumulatorsLabel: NSTextField!
    @IBOutlet weak var doneButton: NSButtonCell!
    @IBOutlet weak var startButton: NSButton!
    
    var engine: Engine?
    var measureKit: EngineMeasureKit?
    var path: URL?
    var averagePrecisions: [Double] = []
    var currentSearchMode: Engine.SearchMode = .ranked
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.doneButton.isEnabled = false
        self.progressBar.doubleValue = 0.0
        self.progressBar.minValue = 0
        
        guard let path = path else {
            return
        }
        
        guard let engine = engine else {
            return
        }
        
        guard let measureKit = EngineMeasureKit(url: path, engine: engine) else {
            return
        }
        
        measureKit.delegate = self
        self.measureKit = measureKit
    }
    
    @IBAction func switchMode(_ sender: Any) {
        let segmentedControl = sender as! NSSegmentedControl
        if segmentedControl.selectedSegment == 0 {
            self.currentSearchMode = .boolean
        } else if segmentedControl.selectedSegment == 1 {
            self.currentSearchMode = .ranked
        }
    }
    
    @IBAction func onDoneTouchUp(_ sender: Any) {
        self.dismiss(nil)
    }
    
    @IBAction func startTouchUp(_ sender: Any) {
        self.startButton.isEnabled = false
        self.doneButton.isEnabled = false
        self.measureKit!.start(withMode: self.currentSearchMode)
    }

    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return false
    }
    
    private func stringFromTimeInterval(interval: TimeInterval) -> String {
        let ti = NSInteger(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        return String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }
}

extension PerformanceViewController: MeasureKitProtocol {
    
    func onPrecisionCalculatedForQuery(queryNb: Int, totalQueries: Int) {
        self.progressBar.maxValue = Double(totalQueries)
        self.currentQueryLabel.stringValue = "Executing test query \(queryNb)"
        self.progressBar.increment(by: 1.0)
    }
    
    func onMeasurementsReady(measure: Measure) {
        self.queryExecutedLabel.stringValue = String(measure.totalQueries)
        self.MAPLabel.stringValue = String((measure.meanAveragePrecision * 100).rounded() / 100)
        self.MRPLabel.stringValue = String((measure.meanResponseTime * 100).rounded() / 100) + "ms"
        self.timeElapsedLabel.stringValue = stringFromTimeInterval(interval: measure.totalTime)
        self.throughputLabel.stringValue = String((measure.throughPut * 100).rounded() / 100) + " q/s"
        self.startButton.isEnabled = true
        self.doneButton.isEnabled = true
    }
}
