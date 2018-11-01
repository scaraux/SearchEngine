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
    
    private var directoryPath: URL
    private var factories: [String: DocumentFactoryProtocol]
    private var documents: [Int: FileDocument]?
    internal var corpusSize: Int {
        if documents == nil {
            readDocuments()
        }
        return documents!.count
    }
    
    init(directoryPath: URL) {
        self.factories = [String: DocumentFactoryProtocol]()
        self.directoryPath = directoryPath
    }
    
    internal func getDocuments() -> [DocumentProtocol] {
        if self.documents == nil {
            readDocuments()
        }
        return Array(self.documents!.values).sorted(by: { $0.documentId < $1.documentId })
    }
    
    internal func getDocumentWith(id: Int) -> DocumentProtocol? {
        return self.documents?[id]
    }
    
    internal func getFileDocumentWith(id: Int) -> FileDocument? {
        return self.documents?[id]
    }
    
    public func readDocuments() {
        
        var docId = 1
        var docs = [Int: FileDocument]()
        
        guard let fileURLs = findFiles() else {
            return
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
        self.documents = docs
    }
    
    private func registerFileDocumentFactoryFor(fileExtension: String, factory: DocumentFactoryProtocol) {
        self.factories[fileExtension] = factory
    }
    
    private func getFileDocumentFactoryFor(fileExtension: String) -> DocumentFactoryProtocol? {
        return self.factories[fileExtension] ?? nil
    }
    
    private func findFiles() -> [URL]? {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: self.directoryPath,
                                                       includingPropertiesForKeys: nil,
                                                       options: [.skipsHiddenFiles,
                                                                 .skipsPackageDescendants,
                                                                 .skipsSubdirectoryDescendants])
            return files.filter { !$0.hasDirectoryPath }
                        .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
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
