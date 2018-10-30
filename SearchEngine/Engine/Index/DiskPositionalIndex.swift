//
//  DiskPositionalIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskPositionalIndex: IndexProtocol {
    
    private(set) var map: [String: [Posting]] = [:]
    private(set) var kGramIndex: GramIndex
    private var diskReader: DiskIndexReader
    
    init?(atPath url: URL) {
        self.kGramIndex = GramIndex()
        do {
            self.diskReader = try DiskIndexReader(atPath: url)
        } catch let error as NSError {
            print(error.description)
            return nil
        }
    }
    
    func getQueryResultsFor(stem: String, fromTerm: String) -> [QueryResult]? {
        return nil
    }
    
    func getPostingsFor(stem: String) -> [Posting]? {
        self.diskReader.getPostings(forTerm: stem)
        return nil
    }
    
    func getVocabulary() -> [String] {
        return []
    }
    
    func getKGramIndex() -> GramIndexProtocol {
        return self.kGramIndex
    }
    
    func clear() {
        
    }
}
