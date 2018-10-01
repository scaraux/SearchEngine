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
    
    init(_ posting: Posting) {
        self.posting = posting
        self.documentId = self.posting.documentId
        self.matchingForTerms = [String]()
        self.matchingForTerms.append(self.posting.term)
    }
    
    func addMatchingTerm(_ term: String) -> Void {
        if self.matchingForTerms.contains(term) == false {
            self.matchingForTerms.insert(term, at: 0)
        }
    }
    
    func addMatchingTerms(terms: [String]) -> Void {
        for term in terms {
            if self.matchingForTerms.contains(term) == false {
                self.matchingForTerms.insert(contentsOf: terms, at: 0)
            }
        }
    }
}
