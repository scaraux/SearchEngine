//
//  PositionalInvertedIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class PositionalInvertedIndex: IndexProtocol {
    
    private(set) var map: [String: [Posting]] = [:]
    private(set) var kGramIndex: GramIndex

    init() {
        self.kGramIndex = GramIndex()
    }
    
    init(withIndex index: [String: [Posting]]) {
        self.map = index
        self.kGramIndex = GramIndex()
    }

    private func withPostings<R>(forTerm term: String, mutations: (inout [Posting]) throws -> R) rethrows -> R {
        return try mutations(&map[term, default: []])
    }
    
    public func getQueryResultsFor(stem: String, fromTerm: String) -> [QueryResult]? {
        if let postings = self.map[stem] {
            return postings.map({ QueryResult($0, term: fromTerm) })
        }
        return nil
    }
    
    public func getPostingsFor(stem: String) -> [Posting]? {
        return self.map[stem]
    }
    
    public func getKGramIndex() -> GramIndexProtocol {
        return self.kGramIndex
    }
    
    public func getVocabulary() -> [String] {
        return Array(self.map.keys).sorted(by: <)
    }
    
    public func addTerm(_ term: String, withId id: Int, atPosition position: Int) {
        withPostings(forTerm: term) { postings in
            if let posting = postings.last, posting.documentId == id {
                posting.addPosition(position)
            } else {
                let posting = Posting(withDocumentId: id, forTerm: term)
                posting.addPosition(position)
                postings.append(posting)                
            }
        }
    }
    
    func dispose() {
        
    }
}

extension PositionalInvertedIndex {
    
    public func getQueryResultsFor(stem: String, fromTerm: String,
                                   withDummyMap map: [String: [Posting]]) -> [QueryResult]? {
        if let postings = map[stem] {
            return postings.map({ QueryResult($0, term: fromTerm) })
        }
        return nil
    }
}
