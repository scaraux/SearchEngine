//
//  ViewController.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, EngineDelegate {

    @IBOutlet weak var directoryPathLabel: NSTextField!
    @IBOutlet weak var queryInput: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    
    var engine = Engine()
    var queryResults: [Result]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.engine.delegate = self
        
        // DEBUG
        self.directoryPathLabel.stringValue = "DEBUG"
        self.engine.initCorpus(withPath: URL(fileURLWithPath: "/Users/rakso/Desktop/CECS/529/Corpus", isDirectory: true))
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func pickBaseFolderWithModal() -> URL? {
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
    
    func onCorpusInitialized() {
        
    }
    
    func onQueryResulted(results: [Result]?) {
//        let documents = results.map { self.corpus!.getDocumentWith(id: $0.documentId)! }

        self.queryResults = results
        self.tableView.reloadData()
    }
    
    @IBAction func chooseFolderTouchUp(_ sender: Any) {
        if let path = pickBaseFolderWithModal() {
            self.directoryPathLabel.stringValue = path.absoluteString
            self.engine.initCorpus(withPath: path)
        }
    }
    
    @IBAction func queryTouchUp(_ sender: Any) {
        let queryString = self.queryInput.stringValue
        self.engine.execQuery(queryString: queryString)
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.queryResults?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
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
}
