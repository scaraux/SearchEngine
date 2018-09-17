//
//  ViewController.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var directoryPathLabel: NSTextField!
    @IBOutlet weak var queryInput: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    
    var queryString: String = ""
    
    var corpus: DocumentCorpusProtocol?
    
    var index: Index?
    
    var queryResults: [Posting] = [Posting]()
    
    var queryParser = BooleanQueryParser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        var q = queryParser.parseQuery(query: "this + is + my + query")

        print("done")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func execQuery(queryString: String) -> Void {
        guard let index = self.index else {
            return
        }
        
        self.queryResults = []
        
        if let results = index.getPostingsFor(term: queryString) {
            self.queryResults = results
        }
        
        self.tableView.reloadData()
//        if let postings: [Posting] = index.getPostings(term: queryString) {
//            for posting in postings {
//                if let doc: Document = corpus!.getDocumentWith(id: posting.documentId) {
//                    print(doc.title)
//                }
//            }
//            self.tableView.reloadData()
//        }
    }

    func initCorpus(withPath path: URL) -> Void {
        self.directoryPathLabel.stringValue = path.absoluteString
        self.corpus = DirectoryCorpus.loadDirectoryCorpus(absolutePath: path, fileExtension: "txt")
        self.index = indexCorpus(self.corpus!)
    }
    
    func indexCorpus(_ corpus: DocumentCorpusProtocol) -> Index {
        let processor: BasicTokenProcessor = BasicTokenProcessor()
        let documents: [Document] = corpus.getDocuments()
        
        let index = InvertedIndex()
    
        for doc in documents {
            guard let stream = doc.getContent() else {
                print("Error: Cannot create stream for file \(doc.documentId)")
                continue
            }
            let tokenStream = EnglishTokenStream(stream)
            let tokens = tokenStream.getTokens()
            
            for rawToken in tokens {
                
                let processedToken: String = processor.processToken(token: rawToken)
                index.addTerm(term: processedToken, documentId: doc.documentId)
            }
            tokenStream.dispose()
        }
        return index
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
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.queryResults.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let posting = self.queryResults[row]
        let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
        cell?.textField?.stringValue = String(posting.documentId)
        return cell
    }
    
    @IBAction func chooseFolderTouchUp(_ sender: Any) {
        if let path = pickBaseFolderWithModal() {
            initCorpus(withPath: path)
        }
    }
    
    @IBAction func queryTouchUp(_ sender: Any) {
        self.queryString = self.queryInput.stringValue
        execQuery(queryString: queryString)
    }
    
}
//
//extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
//
//    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
//        return self.queryResults.count
//    }
//
//    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
//
//        let posting = self.queryResults[row]
//        let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
//        cell?.textField?.stringValue = String(posting.documentId)
//        return cell
//    }
//}

