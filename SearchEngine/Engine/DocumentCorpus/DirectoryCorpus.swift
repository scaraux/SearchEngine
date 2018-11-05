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
    
    private var directoryPath: URL?
    private var factories: [String: DocumentFactoryProtocol]
    private var documents: [Int: FileDocument]?
    internal var corpusSize: Int {
        if documents == nil {
            readDocuments()
        }
        return documents!.count
    }
    
    static let shared = DirectoryCorpus()
    
    private init() {
        self.factories = [:]
        self.directoryPath = nil
    }
    
    public func setDirectoryPath(directoryPath url: URL) {
        self.factories = [:]
        self.directoryPath = url
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
        guard let path = self.directoryPath else {
            return nil
        }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: path,
                                                       includingPropertiesForKeys: nil,
                                                       options: [.skipsHiddenFiles,
                                                                 .skipsPackageDescendants,
                                                                 .skipsSubdirectoryDescendants])
            return files.filter { !$0.hasDirectoryPath }
                        .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        } catch {
            print("Error while enumerating files \(path): \(error.localizedDescription)")
            return nil
        }
    }
    
    static func loadDirectoryCorpus(absolutePath: URL) {
        DirectoryCorpus.shared.setDirectoryPath(directoryPath: absolutePath)
        DirectoryCorpus.shared.registerFileDocumentFactoryFor(fileExtension: "txt",
                                                              factory: TextFileDocument.getFactory())
        DirectoryCorpus.shared.registerFileDocumentFactoryFor(fileExtension: "json",
                                                              factory: JsonFileDocument.getFactory())
    }
}
