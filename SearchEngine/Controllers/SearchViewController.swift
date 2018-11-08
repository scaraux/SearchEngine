//
//  ViewController.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Cocoa

class SearchViewController: NSViewController, NSTextFieldDelegate, EngineDelegate {

    enum TableViewDisplayMode {
        case queryResultsMode
        case vocabularyMode
    }
    
    struct Constants {
        static let maximumVocabularyDisplayed: Int = 1000
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
    var vocabulary: [String]?
    var tableViewMode: TableViewDisplayMode = .queryResultsMode
    var searchMode: Engine.SearchMode = .ranked
    var timeStamp: DispatchTime?
    var isQueryExecuting: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.engine.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.doubleAction = #selector(onTableViewRowDoubleClicked)
        self.queryInput.delegate = self
        self.resultsLabel.stringValue = "0 results"
        self.durationLabel.isHidden = true
        self.searchButton.isEnabled = false
        self.circularProgressBar.isHidden = true
        self.tableView.sizeLastColumnToFit()
        
        setTableViewMode(to: .queryResultsMode)
    }
    
    override func keyDown(with event: NSEvent) {
        if (event.characters?.contains("\r"))! && !isQueryExecuting {
            triggerQuery()
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) && !isQueryExecuting {
            triggerQuery()
            return true
        }
        return false
    }
    
    private func calculateDuration() -> Double {
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - self.timeStamp!.uptimeNanoseconds
        let diff = Double(nanoTime) / 1_000_000_000
        let ret = Double(round(1000*diff)/1000)
        return ret
    }

    private func preQuery() {
        self.isQueryExecuting = true
        self.timeStamp = DispatchTime.now()
        self.durationLabel.isHidden = true
        self.queryResults?.removeAll()
        self.searchButton.isEnabled = false
        self.circularProgressBar.isHidden = false
        self.circularProgressBar.startAnimation(self)
    }
    
    private func postQuery() {
        self.isQueryExecuting = false
        self.durationLabel.isHidden = false
        self.searchButton.isEnabled = true
        self.circularProgressBar.isHidden = true
        self.durationLabel.stringValue = "\(calculateDuration())ms"
        self.circularProgressBar.stopAnimation(self)
    }
    
    /// "park national" camping
    private func triggerQuery() {
        preQuery()
        let queryString = self.queryInput.stringValue
        if queryString.isEmpty == false {
            self.engine.execQuery(queryString: queryString, mode: self.searchMode)
        }
        else {
            self.tableView.reloadData()
        }
    }
    
    private func preLoadEnv() {
        self.circularProgressBar.isHidden = false
        self.circularProgressBar.startAnimation(self)
    }
    
    private func postLoadEnv() {
        self.searchButton.isEnabled = true
        self.circularProgressBar.isHidden = true
        self.circularProgressBar.stopAnimation(self)
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
            self.tableView.tableColumns[1].isHidden = false
            self.tableView.tableColumns[1].width = 150.0
            self.tableView.tableColumns[1].minWidth = 150.0
            self.tableView.tableColumns[2].isHidden = false
            self.tableView.tableColumns[2].width = 150.0
            self.tableViewMode = .queryResultsMode
        }
        else if mode == .vocabularyMode {
            self.tableView.tableColumns[0].headerCell.title = "Words"
            self.tableView.tableColumns[0].maxWidth = 500.0
            self.tableView.tableColumns[1].isHidden = true
            self.tableView.tableColumns[2].isHidden = true
            self.tableViewMode = .vocabularyMode
        }
    }
    
    private func pickBaseFolderWithModal() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select a folder"
        openPanel.message = "Pick a folder"
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
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCorpusInitView" {
            if let vc = segue.destinationController as? CorpusLoadViewController {
                self.engine.initDelegate = vc
            }
        }
    }
    
    private func dialogOKCancel(question: String, text: String) {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
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
        if let path = pickBaseFolderWithModal() {
            self.directoryPathLabel.stringValue = "/" + path.lastPathComponent
            performSegue(withIdentifier: "ShowCorpusInitView", sender: self)
            self.engine.newEnvironment(withPath: path)
        }
    }
    
    @IBAction func openEnvironment(_ sender: Any) {
        if let path = pickBaseFolderWithModal() {
            self.directoryPathLabel.stringValue = "/" + path.lastPathComponent
            preLoadEnv()
            self.engine.loadEnvironment(withPath: path)
        }
    }
    
    @IBAction func stemWord(_ sender: Any) {
        let word = self.queryInput.stringValue
        if word.isEmpty == false {
            let stem = self.engine.stemWord(word: word)
            dialogOKCancel(question: "Stem", text: stem)
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
            guard let result = self.queryResults?[row] else {
                return nil
            }
            if tableColumn == tableView.tableColumns[0] {
                let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier),
                                              owner: self) as? NSTableCellView
                cell?.textField?.stringValue = String(result.documentId)
                return cell
            }
            
            if tableColumn == tableView.tableColumns[1] {
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
        let alert = NSAlert()
        alert.messageText = "Environment loaded"
        alert.informativeText = "Environment has successfully been loaded."
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func onEnvironmentLoadingFailed(withError error: String) {
        postLoadEnv()
        let alert = NSAlert()
        alert.messageText = "Environment not loaded"
        alert.informativeText = "Could not load environment. \(error)"
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func onQueryResulted(results: [QueryResult]?) {
        postQuery()
        if self.tableViewMode != .queryResultsMode {
            setTableViewMode(to: .queryResultsMode)
        }
        if results == nil {
            self.queryResults = []
            self.resultsLabel.stringValue = "0 result"
        } else {
            self.queryResults = results
            self.resultsLabel.stringValue = "\(results!.count) result(s)"
        }
        self.tableView.reloadData()
        self.tableView.sizeLastColumnToFit()
    }
}
