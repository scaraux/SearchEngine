//
//  DocumentCorpusProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol DocumentCorpusProtocol {
    
    var corpusSize: Int { get }
    func getDocuments() -> [DocumentProtocol]
    func getDocumentWith(id: Int) -> DocumentProtocol?
    func getFileDocumentWith(id: Int) -> FileDocument?
    func readDocuments()
}
