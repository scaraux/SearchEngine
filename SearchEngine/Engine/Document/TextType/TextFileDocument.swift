//
//  TextFileDocument.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class TextFileDocument: FileDocument {
    
    private(set) var fileName: String
    private(set) var fileURL: URL
    private(set) var documentId: Int
    private(set) var title: String
    var weight: Double = 0

    init(id: Int, fileURL: URL) {
        self.fileURL = fileURL
        self.documentId = id
        self.title = fileURL.lastPathComponent
        self.fileName = fileURL.lastPathComponent
    }

    func getContent() -> StreamReader? {
        return StreamReader(url: self.fileURL)
    }
    
    static func getFactory() -> DocumentFactoryProtocol {
        return TextFileDocumentFactory()
    }
}

class TextFileDocumentFactory: DocumentFactoryProtocol {
    func createDocument(_ id: Int, _ fileURL: URL) -> FileDocument {
        return TextFileDocument(id: id, fileURL: fileURL)
    }
}
