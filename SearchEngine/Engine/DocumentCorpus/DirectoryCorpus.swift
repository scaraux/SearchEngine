//
//  DirectoryCorpus.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation
import Cocoa

class DirectoryCorpus: DocumentCorpusProtocol {
    
    let fileManager = FileManager.default
    
    var directoryPath: URL

    var corpusSize: Int {
        get {
            if documents == nil {
                documents = readDocuments()
            }
            return documents!.count
        }
    }
    private var factories: [String : DocumentFactoryProtocol]
    
    private var documents: [Int : FileDocument]?

    init(directoryPath: URL) {
        self.factories = [String : DocumentFactoryProtocol]()
        self.directoryPath = directoryPath
    }
    
    func readDocuments() -> [Int : FileDocument] {
        
        var docId = 1
        var docs = [Int : FileDocument]()
        
        guard let fileURLs = findFiles() else {
            return docs
        }
        
        for url in fileURLs {
            let factoryForUrl = getFileDocumentFactoryFor(fileExtension: url.pathExtension)
            if factoryForUrl == nil {
                print("File extension not recognized: .\(url.pathExtension)")
                continue
            }
            docs[docId] = factoryForUrl!.createDocument(docId, url)
            docId += 1
        }
        return docs
    }
    
    func getDocuments() -> [DocumentProtocol] {
        if self.documents == nil {
            self.documents = readDocuments()
        }
        return Array(self.documents!.values).sorted(by: { $0.documentId < $1.documentId })
    }
    
    func getDocumentWith(id: Int) -> DocumentProtocol? {
        return self.documents?[id]
    }
    
    func getFileDocumentWith(id: Int) -> FileDocument? {
        return self.documents?[id]
    }
    
    func registerFileDocumentFactoryFor(fileExtension: String, factory: DocumentFactoryProtocol) {
        self.factories[fileExtension] = factory
    }
    
    func getFileDocumentFactoryFor(fileExtension: String) -> DocumentFactoryProtocol? {
        return self.factories[fileExtension] ?? nil
    }
    
    private func findFiles() -> [URL]? {

        do {
            let files = try fileManager.contentsOfDirectory(at: self.directoryPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            return files
        } catch {
            print("Error while enumerating files \(directoryPath.path): \(error.localizedDescription)")
            return nil
        }
    }
    
    static func loadDirectoryCorpus(absolutePath: URL) -> DirectoryCorpus? {
        let corpus: DirectoryCorpus = DirectoryCorpus(directoryPath: absolutePath)
        corpus.registerFileDocumentFactoryFor(fileExtension: "txt", factory: TextFileDocument.getFactory())
        corpus.registerFileDocumentFactoryFor(fileExtension: "json", factory: JsonFileDocument.getFactory())
        return corpus
    }
}
