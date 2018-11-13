//
//  WildcardLiteral.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/30/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation
import PorterStemmer2

class WildcardLiteral: Queriable {

    var term: String

    init(term: String) {
        self.term = term
    }
    
    func getResultsFrom(index: IndexProtocol) -> [QueryResult]? {
        var mergedResults = [QueryResult]()
        let kGramIndex = index.getKGramIndex()

        guard var candidates = kGramIndex.getMatchingCandidatesFor(term: self.term) else {
            return nil
        }

        if let postings = index.getPostingsWithoutPositionsFor(stem: candidates[0].stem) {
            mergedResults = convertToQueryResults(postings: postings, fromTerm: candidates[0].type)
        }

        for i in 1 ..< candidates.count {
            if let postings = index.getPostingsWithoutPositionsFor(stem: candidates[i].stem) {
                let newResults = convertToQueryResults(postings: postings, fromTerm: candidates[i].type)
                mergedResults = union(left: mergedResults, right: newResults)
            }
        }
        return mergedResults
    }
    
    private func union(left: [QueryResult], right: [QueryResult]) -> [QueryResult] {
        
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
                queryResults.append(right[j])
                j += 1
            }
            else if left[i].documentId < right[j].documentId {
                queryResults.append(left[i])
                i += 1
            }
        }
        
        if i < left.count {
            while i < left.count {
                queryResults.append(left[i])
                i += 1
            }
        }
        
        if j < right.count {
            while j < right.count {
                queryResults.append(right[j])
                j += 1
            }
        }
        return queryResults
    }
    
    func toString() -> String {
        return self.term
    }
}
