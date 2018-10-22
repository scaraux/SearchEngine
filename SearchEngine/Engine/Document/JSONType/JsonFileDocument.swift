//
//  JsonFileDocument.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/2/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class JsonFileDocument : FileDocument {
    
    var fileName: String
    var fileURL: URL
    var documentId: Int
    var title: String {
        get {
            return getTitle() ?? ""
        }
    }
    
    var content: StreamReader?
    
    init(id: Int, fileURL: URL) {
        
        self.fileURL = fileURL
        self.documentId = id
        self.content = nil
        self.fileName = fileURL.lastPathComponent
    }
    
    private func getTitle() -> String? {
        if let data = NSData(contentsOf: fileURL) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
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
                if let json = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
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

class JsonFileDocumentFactory : DocumentFactoryProtocol {
    func createDocument(_ id: Int, _ fileURL: URL) -> FileDocument {
        return JsonFileDocument(id: id, fileURL: fileURL)
    }
}
