//
//  DiskPositionalIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskPositionalIndex<T: FixedWidthInteger, U: FixedWidthInteger>: IndexProtocol {

    private(set) var kGramIndex: GramIndex
    private var diskIndexUtility: DiskIndexUtility<T, U>
    
    init(atPath url: URL, utility: DiskIndexUtility<T, U>) {
        self.kGramIndex = GramIndex()
        self.diskIndexUtility = utility
    }
    
    func getQueryResultsFor(stem: String, fromTerm: String) -> [QueryResult]? {
        if let postings = self.diskIndexUtility.getPostings(forTerm: stem) {
            return postings.map({ QueryResult($0, term: fromTerm) })
        }
        return nil
    }
    
    func getPostingsFor(stem: String) -> [Posting]? {
        return self.diskIndexUtility.getPostings(forTerm: stem)
    }
    
    func getVocabulary() -> [String] {
        return []
    }
    
    func getKGramIndex() -> GramIndexProtocol {
        return self.kGramIndex
    }
    
    func dispose() {
        self.diskIndexUtility.dispose()
    }
}
