//
//  ViewController.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Cocoa

//fileprivate extension Selector {
//    static let onTableViewRowDoubleClicked = #selector(onTableViewRowDoubleClicked)
//}

class ViewController: NSViewController, NSTextFieldDelegate, EngineDelegate {

    enum TableViewDisplayMode {
        case QueryResultsMode
        case VocabularyMode
    }
    
    struct Constants {
        static let maximumVocabularyDisplayed: Int = 1000
    }

    @IBOutlet weak var directoryPathLabel: NSTextField!
    @IBOutlet weak var queryInput: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var timeElapsedLabel: NSTextField!
    
    var engine = Engine()
    var queryResults: [QueryResult]?
    var vocabulary: [String]?
    var tableViewMode: TableViewDisplayMode = .QueryResultsMode
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.engine.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.doubleAction = #selector(onTableViewRowDoubleClicked)
        self.queryInput.delegate = self
        self.progressBar.isHidden = true
        self.timeElapsedLabel.isHidden = true
        self.tableView.sizeLastColumnToFit()
        
        setTableViewMode(to: .QueryResultsMode)
    }

    override var representedObject: Any? {
        didSet {
        
        }
    }

    
    override func keyDown(with event: NSEvent) {
        if (event.characters?.contains("\r"))! {
            triggerQuery()
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            triggerQuery()
            return true
        }
        return false
    }
    
    func onCorpusIndexingStarted(elementsToIndex: Int) {
        self.timeElapsedLabel.isHidden = true
        self.progressBar.isHidden = false
        self.progressBar.doubleValue = 0.0
        self.progressBar.minValue = 0
        self.progressBar.maxValue = Double(elementsToIndex)
    }
    
    func onCorpusIndexedOneMoreDocument() {
        self.progressBar.increment(by: 1.0)
    }
    
    func onCorpusInitialized(timeElapsed: Double) {
        self.timeElapsedLabel.isHidden = false
        self.timeElapsedLabel.stringValue = "Time elapsed: \(timeElapsed)"
        self.progressBar.isHidden = true
    }
    
    func onQueryResulted(results: [QueryResult]?) {
        self.queryResults = results
        if self.tableViewMode != .QueryResultsMode {
            setTableViewMode(to: .QueryResultsMode)
        }
        self.tableView.reloadData()
        self.tableView.sizeLastColumnToFit()
    }
    
    private func triggerQuery() -> Void {
        self.queryResults?.removeAll()
        let queryString = self.queryInput.stringValue
        if queryString.isEmpty == false {
            self.engine.execQuery(queryString: queryString)
        }
        else {
            self.tableView.reloadData()
        }
    }
    
    @objc private func onTableViewRowDoubleClicked() -> Void {
        let selectedRow = self.tableView.selectedRow
        guard let relatedQueryResult = self.queryResults?[selectedRow] else {
            return
        }
        openFilePreviewController(queryResult: relatedQueryResult)
    }
    
    private func setTableViewMode(to mode: TableViewDisplayMode) -> Void {
        if mode == .QueryResultsMode {
            self.tableView.tableColumns[0].headerCell.title = "Id"
            self.tableView.tableColumns[0].width = 50.0
            self.tableView.tableColumns[0].minWidth = 50.0
            self.tableView.tableColumns[0].maxWidth = 50.0
            self.tableView.tableColumns[1].isHidden = false
            self.tableView.tableColumns[1].width = 150.0
            self.tableView.tableColumns[1].minWidth = 150.0
            self.tableView.tableColumns[2].isHidden = false
            self.tableView.tableColumns[2].width = 150.0
            self.tableViewMode = .QueryResultsMode
        }
        else if mode == .VocabularyMode {
            self.tableView.tableColumns[0].headerCell.title = "Words"
            self.tableView.tableColumns[0].maxWidth = 500.0
            self.tableView.tableColumns[1].isHidden = true
            self.tableView.tableColumns[2].isHidden = true
            self.tableViewMode = .VocabularyMode
        }
    }
    
    private func pickBaseFolderWithModal() -> URL? {
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a folder"
        openPanel.message = "Pick a folder"
        openPanel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        openPanel.showsResizeIndicator = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = false
        let r = openPanel.runModal()
        if r == NSApplication.ModalResponse.OK {
            return openPanel.url!
        }
        return nil
    }

    private func openFilePreviewController(queryResult: QueryResult) -> Void {
        var secondaryWindow: NSWindow? = nil
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let previewController: FilePreviewController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "FilePreviewController")) as! FilePreviewController
        previewController.queryData = queryResult
        secondaryWindow = NSWindow(contentViewController: previewController)
        secondaryWindow?.setContentSize(NSSize(width: 700, height: 1000))
        secondaryWindow!.makeKeyAndOrderFront(self)
        let windowController = NSWindowController(window: secondaryWindow)
        windowController.showWindow(self)
    }
    
    @IBAction func chooseFolderTouchUp(_ sender: Any) {
        if let path = pickBaseFolderWithModal() {
            self.directoryPathLabel.stringValue = path.absoluteString
            self.engine.initCorpus(withPath: path)
        }
    }
    
    @IBAction func queryTouchUp(_ sender: Any) {
        triggerQuery()
    }
    
    @IBAction func showVocabulary(_ sender: Any) {
        self.vocabulary = self.engine.getVocabulary()
        self.setTableViewMode(to: .VocabularyMode)
        self.tableView.reloadData()
        self.tableView.sizeLastColumnToFit()
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if self.tableViewMode == .QueryResultsMode {
          return self.queryResults?.count ?? 0
        }
        else if self.tableViewMode == .VocabularyMode {
            guard let vocabularyCount = self.vocabulary?.count else {
                return 0
            }
            return vocabularyCount > Constants.maximumVocabularyDisplayed ? Constants.maximumVocabularyDisplayed : vocabularyCount
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
         if self.tableViewMode == .QueryResultsMode {
            guard let result = self.queryResults?[row] else {
                return nil
            }
            if tableColumn == tableView.tableColumns[0] {
                let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
                cell?.textField?.stringValue = String(result.documentId)
                return cell
            }
            
            if tableColumn == tableView.tableColumns[1] {
                let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
                cell?.textField?.stringValue = String(result.document!.title)
                return cell
            }
            let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
            cell?.textField?.stringValue = result.matchingForTerms.compactMap({$0}).joined(separator: " ")
            return cell
        }
        else if self.tableViewMode == .VocabularyMode {
            guard let vocabularyEntry = self.vocabulary?[row] else {
                return nil
            }
            if tableColumn == tableView.tableColumns[0] {
                let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
                cell?.textField?.stringValue = String(vocabularyEntry)
                return cell
            }
        }
        return nil
    }
}
