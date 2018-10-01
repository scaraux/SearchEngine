//
//  WildcardLiteral.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/30/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class WildcardLiteral: QueryComponent {

    var term: String

    init(term: String) {
        self.term = term
    }
    
    func getResultsFrom(index: Index) -> [QueryResult]? {
        var grams = KGramIndex.shared().getMatchingGramsFor(term: self.term)
        
        for gram in grams {
            
            var candidates = KGramIndex.shared().getMatchingCandidatesFor(gram: gram)
        }
        
        
        return nil
    }
    
    func andMerge(left: [QueryResult], right: [QueryResult]) -> [QueryResult] {
        
        var queryResults = [QueryResult]()
        var i: Int = 0
        var j: Int = 0
        
        while i < left.count && j < right.count {
            if left[i].documentId == right[j].documentId {
                right[j].addMatchingTerms(terms: left[i].matchingForTerms)
                queryResults.append(right[j])
                i += 1
                j += 1
            }
            else if left[i].documentId > right[j].documentId {
                j += 1
            }
            else if left[i].documentId < right[j].documentId {
                i += 1
            }
        }
        return queryResults
    }
    
    
    func toString() -> String {
        return self.term
    }
}
