//
//  DocumentCorpusProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol DocumentCorpus {
    
    var corpusSize: Int { get }
    
    func getDocuments() -> [Document]
    
    func getDocumentWith(id: Int) -> Document?
}
