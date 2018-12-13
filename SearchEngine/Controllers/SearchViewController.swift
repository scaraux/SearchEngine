//
//  ViewController.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Cocoa

class SearchViewController: NSViewController, NSTextFieldDelegate, EngineDelegate, SpellingCorrectionDelegate {

    enum TableViewDisplayMode {
        case queryResultsMode
        case vocabularyMode
    }
    
    struct Constants {
        static let maximumVocabularyDisplayed: Int = 1000
        static let zeroResultsString: String = "0 result(s)"
        static let environmentLoadedMessage: String = "Environment loaded"
        static let environmentLoadedDescription: String =
        "Environment has successfully been loaded. You can now trigger queries."
        static let environmentNotLoadedMessage: String = "Environment not loaded"
        static let selectDirectoryMessage: String = "Select a directory"
    }
    
    @IBOutlet weak var directoryPathLabel: NSTextField!
    @IBOutlet weak var queryInput: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var resultsLabel: NSTextField!
    @IBOutlet weak var searchModeSegmentedControl: NSSegmentedCell!
    @IBOutlet weak var searchButton: NSButton!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var circularProgressBar: NSProgressIndicator!
    
    var engine = Engine()
    var queryResults: [QueryResult]?
    var corrections: [SpellingSuggestion]?
    var vocabulary: [String]?
    var tableViewMode: TableViewDisplayMode = .queryResultsMode
    var searchMode: Engine.SearchMode = .ranked
    var timeStamp: DispatchTime?
    var isEnvironmentLoaded: Bool = false
    var isQueryExecuting: Bool = false
    var performanceDirectoryPath: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func keyDown(with event: NSEvent) {
        if (event.characters?.contains("\r"))! && !isQueryExecuting {
            if queryInput.stringValue != "" {
                triggerQuery()
            }
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) && !isQueryExecuting {
            if queryInput.stringValue != "" {
                triggerQuery()
            }
            return true
        }
        return false
    }
    
    private func configure() {
        self.engine.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.doubleAction = #selector(onTableViewRowDoubleClicked)
        self.queryInput.delegate = self
        self.resultsLabel.stringValue = Constants.zeroResultsString
        self.durationLabel.isHidden = true
        self.searchButton.isEnabled = false
        self.circularProgressBar.isHidden = true
        self.tableView.sizeLastColumnToFit()
        
        setTableViewMode(to: .queryResultsMode)
    }
    
    private func roundDouble(value: Double) -> Double {
        return Double(round(1000*value)/1000)
    }
    
    private func calculateDuration() -> Double {
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - self.timeStamp!.uptimeNanoseconds
        let diff = Double(nanoTime) / 1_000_000_000
        return roundDouble(value: diff)
    }

    private func preQuery() {
        guard isEnvironmentLoaded else {
            dialogOKCancel(question: "Could not trigger query",
                           text: "You need to load en environment first.",
                           mode: .warning)
            return
        }
        self.isQueryExecuting = true
        self.timeStamp = DispatchTime.now()
        self.durationLabel.isHidden = true
        self.queryResults?.removeAll()
        self.searchButton.isEnabled = false
        self.circularProgressBar.isHidden = false
        self.circularProgressBar.startAnimation(self)
    }
    
    private func triggerQuery() {
        let queryString = self.queryInput.stringValue
        if queryString.isEmpty == false {
            preQuery()
            self.engine.execQuery(queryString: queryString, mode: self.searchMode)
        }
        else {
            self.tableView.reloadData()
        }
    }
    
    private func postQuery() {
        self.durationLabel.isHidden = false
        self.searchButton.isEnabled = true
        self.circularProgressBar.isHidden = true
        self.durationLabel.stringValue = "\(calculateDuration())ms"
        self.circularProgressBar.stopAnimation(self)
        self.isQueryExecuting = false
    }
    
    private func preLoadEnv() {
        self.circularProgressBar.isHidden = false
        self.circularProgressBar.startAnimation(self)
    }
    
    private func postLoadEnv() {
        self.searchButton.isEnabled = true
        self.circularProgressBar.isHidden = true
        self.circularProgressBar.stopAnimation(self)
        self.isEnvironmentLoaded = true
    }
    
    @objc private func onTableViewRowDoubleClicked() {
        let selectedRow = self.tableView.selectedRow
        guard let relatedQueryResult = self.queryResults?[selectedRow] else {
            return
        }
        openFilePreviewController(queryResult: relatedQueryResult)
    }
    
    private func setTableViewMode(to mode: TableViewDisplayMode) {
        if mode == .queryResultsMode {
            self.tableView.tableColumns[0].headerCell.title = "Id"
            self.tableView.tableColumns[0].width = 50.0
            self.tableView.tableColumns[0].minWidth = 50.0
            self.tableView.tableColumns[0].maxWidth = 50.0
            
            if self.searchMode == .ranked {
                self.tableView.tableColumns[1].isHidden = false
                self.tableView.tableColumns[1].width = 50.0
                self.tableView.tableColumns[1].minWidth = 50.0
            }
            else {
                self.tableView.tableColumns[1].isHidden = true
            }

            self.tableView.tableColumns[2].isHidden = false
            self.tableView.tableColumns[2].width = 150.0
            self.tableView.tableColumns[2].minWidth = 150.0
            
            self.tableView.tableColumns[3].isHidden = false
            self.tableView.tableColumns[3].width = 150.0
            self.tableViewMode = .queryResultsMode
            
        }
        else if mode == .vocabularyMode {
            self.tableView.tableColumns[0].headerCell.title = "Terms"
            self.tableView.tableColumns[0].maxWidth = 500.0
            
            self.tableView.tableColumns[1].isHidden = true
            self.tableView.tableColumns[2].isHidden = true
            self.tableView.tableColumns[3].isHidden = true
            self.tableViewMode = .vocabularyMode
        }
    }
    
    private func selectDirectoryWithModal(withTitle title: String) -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.title = title
        openPanel.message = title
        openPanel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        openPanel.showsResizeIndicator = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = false
        let ret = openPanel.runModal()
        if ret == NSApplication.ModalResponse.OK {
            return openPanel.url!
        }
        return nil
    }

    private func openFilePreviewController(queryResult: QueryResult) {
        var secondaryWindow: NSWindow?
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let previewController: FilePreviewController = storyboard.instantiateController(
            withIdentifier: "FilePreviewController") as! FilePreviewController
        previewController.queryData = queryResult
        secondaryWindow = NSWindow(contentViewController: previewController)
        secondaryWindow?.setContentSize(NSSize(width: 700, height: 1000))
        secondaryWindow!.makeKeyAndOrderFront(self)
        let windowController = NSWindowController(window: secondaryWindow)
        windowController.showWindow(self)
    }
    
    private func dialogOKCancel(question: String, text: String, mode: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = mode
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCorpusInitView" {
            if let vc = segue.destinationController as? CorpusLoadViewController {
                self.engine.initDelegate = vc
                self.engine.loadDelegate = vc
            }
        }
        
        if segue.identifier == "ShowPerformanceView" {
            if let vc = segue.destinationController as? PerformanceViewController {
                vc.engine = self.engine
                vc.path = self.performanceDirectoryPath
            }
        }
        
        if segue.identifier == "ShowSpellingCorrectionView" {
            if let vc = segue.destinationController as? SpellingCorrectionViewController {
                vc.delegate = self
                vc.corrections = self.corrections
            }
        }
    }
}

extension SearchViewController {
    
    @IBAction func didSwitchMode(_ sender: Any) {
        let segmentedControl = sender as! NSSegmentedControl
        if segmentedControl.selectedSegment == 0 {
            self.searchMode = .boolean
        } else if segmentedControl.selectedSegment == 1 {
            self.searchMode = .ranked
        }
    }
    
    @IBAction func queryTouchUp(_ sender: Any) {
        triggerQuery()
    }
    
    @IBAction func newEnvironment(_ sender: Any) {
        if let path = selectDirectoryWithModal(withTitle: Constants.selectDirectoryMessage) {
            self.directoryPathLabel.stringValue = "/" + path.lastPathComponent
            performSegue(withIdentifier: "ShowCorpusInitView", sender: self)
            self.engine.newEnvironment(withPath: path)
        }
    }
    
    @IBAction func openEnvironment(_ sender: Any) {
        if let path = selectDirectoryWithModal(withTitle: Constants.selectDirectoryMessage) {
            self.directoryPathLabel.stringValue = "/" + path.lastPathComponent
            preLoadEnv()
            performSegue(withIdentifier: "ShowCorpusInitView", sender: self)
            self.engine.loadEnvironment(withPath: path)
        }
    }
    
    @IBAction func perfTestTouchUp(_ sender: Any) {
        if let path = selectDirectoryWithModal(withTitle: Constants.selectDirectoryMessage) {
            self.performanceDirectoryPath = path
            performSegue(withIdentifier: "ShowPerformanceView", sender: self)
        }
    }
    
    @IBAction func stemWord(_ sender: Any) {
        let word = self.queryInput.stringValue
        if word.isEmpty == false {
            let stem = self.engine.stemWord(word: word)
            dialogOKCancel(question: "Stem", text: stem, mode: .informational)
        }
    }
    
    @IBAction func showVocabulary(_ sender: Any) {
        self.vocabulary = self.engine.getVocabulary()
        self.setTableViewMode(to: .vocabularyMode)
        self.tableView.reloadData()
        self.tableView.sizeLastColumnToFit()
    }
}

extension SearchViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if self.tableViewMode == .queryResultsMode {
          return self.queryResults?.count ?? 0
        }
        else if self.tableViewMode == .vocabularyMode {
            guard let vocabularyCount = self.vocabulary?.count else {
                return 0
            }
            return vocabularyCount > Constants.maximumVocabularyDisplayed ?
                Constants.maximumVocabularyDisplayed : vocabularyCount
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
         if self.tableViewMode == .queryResultsMode {
            guard let results = self.queryResults else {
                return nil
            }
            if results.count == 0 || row >= results.count {
                return nil
            }
            let result = self.queryResults![row]
            if tableColumn == tableView.tableColumns[0] {
                let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier),
                                              owner: self) as? NSTableCellView
                cell?.textField?.stringValue = String(result.documentId)
                return cell
            }
            if tableColumn == tableView.tableColumns[1] {
                let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier),
                                              owner: self) as? NSTableCellView
                if result.score != 0.0 {
                    let displayableScore = String(roundDouble(value: result.score))
                    cell?.textField?.stringValue = displayableScore
                } else {
                    cell?.textField?.stringValue = ""
                }
                return cell
            }
            if tableColumn == tableView.tableColumns[2] {
                let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier),
                                              owner: self) as? NSTableCellView
                cell?.textField?.stringValue = String(result.document!.title)
                return cell
            }
            let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
            cell?.textField?.stringValue = result.matchingForTerms.compactMap({$0}).joined(separator: " ")
            return cell
        }
        else if self.tableViewMode == .vocabularyMode {
            guard let vocabularyEntry = self.vocabulary?[row] else {
                return nil
            }
            if tableColumn == tableView.tableColumns[0] {
                let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier),
                                              owner: self) as? NSTableCellView
                cell?.textField?.stringValue = String(vocabularyEntry)
                return cell
            }
        }
        return nil
    }
}

extension SearchViewController {
    
    func onEnvironmentLoaded() {
        postLoadEnv()
    }
    
    func onEnvironmentLoadingFailed(withError error: String) {
        postLoadEnv()
        dialogOKCancel(question: Constants.environmentNotLoadedMessage,
                       text: "\(error)",
                       mode: .critical)
    }
    
    func onQueryResulted(results: [QueryResult]?) {
        postQuery()
        if results == nil {
            self.queryResults = []
            self.resultsLabel.stringValue = Constants.zeroResultsString
        } else {
            self.queryResults = results
            self.resultsLabel.stringValue = "\(results!.count) result(s)"
        }
        setTableViewMode(to: .queryResultsMode)
        self.tableView.reloadData()
        self.tableView.sizeLastColumnToFit()
    }
    
    func onFoundSpellingCorrections(corrections: [SpellingSuggestion]) {
        self.corrections = corrections
        performSegue(withIdentifier: "ShowSpellingCorrectionView", sender: nil)
    }
    
    func onRequestApplySuggestion(suggestion: SpellingSuggestion) {
        let currentQuery: String = self.queryInput.stringValue
        let updatedQuery: String = currentQuery.replacingOccurrences(of: suggestion.mispelledTerm,
                                                                     with: suggestion.suggestedTerm)
        self.queryInput.stringValue = updatedQuery
    }
}
