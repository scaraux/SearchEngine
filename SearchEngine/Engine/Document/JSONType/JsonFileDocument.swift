//
//  JsonFileDocument.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/2/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class JsonFileDocument: FileDocument {

    private(set) var fileName: String
    private(set) var fileURL: URL
    private(set) var documentId: Int
    private(set) var content: StreamReader?
    var weight: Double = 0
    var title: String { return getTitle() ?? "" }
    
    init(id: Int, fileURL: URL) {
        self.fileURL = fileURL
        self.documentId = id
        self.content = nil
        self.fileName = fileURL.lastPathComponent
    }
    
    private func getTitle() -> String? {
        if let data = NSData(contentsOf: fileURL) {
            do {
                let options = JSONSerialization.ReadingOptions.allowFragments
                if let json = try JSONSerialization.jsonObject(with: data as Data,
                                                               options: options) as? [String: AnyObject] {
                    return json["title"] as? String
                }
            }
            catch {
                fatalError("Error: Cannot deserialize json file \(fileURL)")
            }
        }
        return nil
    }
    
    func getContent() -> StreamReader? {
        if let data = NSData(contentsOf: fileURL) {
            do {
                let options = JSONSerialization.ReadingOptions.allowFragments
                if let json = try JSONSerialization.jsonObject(with: data as Data,
                                                               options: options) as? [String: AnyObject] {
                    let contentString = json["body"] as! String
                    return StreamReader(data: contentString.data(using: .utf8)!)
                }
            }
            catch {
                fatalError("Error: Cannot deserialize json file \(fileURL)")
            }
        }
        return nil
    }
    
    static func getFactory() -> DocumentFactoryProtocol {
        return JsonFileDocumentFactory()
    }
}

class JsonFileDocumentFactory: DocumentFactoryProtocol {
    func createDocument(_ id: Int, _ fileURL: URL) -> FileDocument {
        return JsonFileDocument(id: id, fileURL: fileURL)
    }
}
