//
//  Result.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/25/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class Result {
    
    var documentId: Int
    var document: Document?
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
            self.matchingForTerms.append(term)
        }
    }
    
    func addMatchingTerms(terms: [String]) -> Void {
        for term in terms {
            if self.matchingForTerms.contains(term) == false {
                self.matchingForTerms.append(term)
            }
        }
    }
}
