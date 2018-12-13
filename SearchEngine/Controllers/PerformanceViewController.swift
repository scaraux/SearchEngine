//
//  PerformanceViewController.swift
//  SearchEngine
//
//  Created by Oscar Götting on 12/12/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Cocoa
import Charts

class PerformanceViewController: NSViewController, NSPopoverDelegate {
    
    var engine: Engine?
    var path: URL?
    var averagePrecisions: [Double] = []
    
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var statisticChart: LineChartView!
    @IBOutlet weak var currentQueryLabel: NSTextField!
    @IBOutlet weak var queryExecutedLabel: NSTextField!
    @IBOutlet weak var MAPLabel: NSTextField!
    @IBOutlet weak var doneButton: NSButtonCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.doneButton.isEnabled = false
        
        guard let path = path else {
            return
        }
        
        guard let engine = engine else {
            return
        }
        
        guard let measureKit = EngineMeasureKit(url: path, engine: engine) else {
            return
        }
        
        self.progressBar.doubleValue = 0.0
        self.progressBar.minValue = 0
        self.progressBar.maxValue = 0.0
        
        measureKit.delegate = self
        measureKit.start()
    }
    
    @IBAction func onDoneTouchUp(_ sender: Any) {
        self.dismiss(nil)
    }
    //    func updateChart() {
//        
//        var lineChartEntry  = [ChartDataEntry]()
//        
//        for i in 0..<self.averagePrecisions.count {
//            let value = ChartDataEntry(x: Double(i), y: self.averagePrecisions[i])
//            lineChartEntry.append(value)
//        }
//        
//        let line1 = LineChartDataSet(values: lineChartEntry, label: "Number")
//        line1.colors = [NSUIColor.blue]
//        line1.mode = .linear
//        
//        let data = LineChartData()
//        data.addDataSet(line1)
//        
//        statisticChart.data = data
//        statisticChart.backgroundColor = NSColor.white
//        statisticChart.chartDescription?.text = "Average precision / query"
//    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return false
    }
}

extension PerformanceViewController: MeasureKitProtocol {
    
    func onPrecisionCalculatedForQuery(queryNb: Int, totalQueries: Int) {
        self.progressBar.maxValue = Double(totalQueries)
        self.currentQueryLabel.stringValue = "Executing test query \(queryNb)"
        self.progressBar.increment(by: 1.0)
    }
    
    func onMeasurementsReady(totalQueries: Int, meanAveragePrecision: Double) {
        self.queryExecutedLabel.stringValue = String(totalQueries)
        self.MAPLabel.stringValue = String(meanAveragePrecision.rounded(.toNearestOrEven) / 1000)
        self.doneButton.isEnabled = true
    }
}
