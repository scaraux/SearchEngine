//
//  DiskPositionalIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskPositionalIndex<T: FixedWidthInteger, U: FixedWidthInteger>: IndexProtocol {
    
    private(set) var map: [String: [Posting]] = [:]
    private(set) var kGramIndex: GramIndex
    private var diskIndexUtility: DiskIndexUtility<T, U>
    
    init(atPath url: URL, utility: DiskIndexUtility<T, U>) {
        self.kGramIndex = GramIndex()
        self.diskIndexUtility = utility
    }
    
    func getQueryResultsFor(stem: String, fromTerm: String) -> [QueryResult]? {
        return nil
    }
    
    func getPostingsFor(stem: String) -> [Posting]? {
        self.diskIndexUtility.getPostings(forTerm: stem)
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
