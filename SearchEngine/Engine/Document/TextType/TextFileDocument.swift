//
//  TextFileDocument.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class TextFileDocument : FileDocument {
    
    var fileName: String

    var fileURL: URL
    
    var documentId: Int
    
    var title: String

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

class TextFileDocumentFactory : DocumentFactoryProtocol {
    func createDocument(_ id: Int, _ fileURL: URL) -> FileDocument {
        return TextFileDocument(id: id, fileURL: fileURL)
    }
}
