//
//  Result.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/25/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class QueryResult {
    
    var documentId: Int
    var document: FileDocument?
    var posting: Posting
    var matchingForTerms: [String]
    var score: Double
    
    init(_ posting: Posting, term: String) {
        self.posting = posting
        self.documentId = self.posting.documentId
        self.matchingForTerms = [String]()
        self.matchingForTerms.append(term)
        self.score = 0.0
    }
    
    init(_ posting: Posting, terms: [String]) {
        self.posting = posting
        self.documentId = self.posting.documentId
        self.matchingForTerms = terms
        self.score = 0.0
    }
    
    func addMatchingTerm(_ term: String) {
        if self.matchingForTerms.contains(term) == false {
            self.matchingForTerms.insert(term, at: 0)
        }
    }
    
    func addMatchingTerms(terms: [String]) {
        for term in terms {
            if self.matchingForTerms.contains(term) == false {
                self.matchingForTerms.insert(contentsOf: terms, at: 0)
            }
        }
    }
}
