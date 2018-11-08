//
//  PhraseLiteral.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/16/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation
import PorterStemmer2

class PhraseLiteral: Queriable {

    private var terms: [String] = [String]()
    
    init(terms: [String]) {
        self.terms.append(contentsOf: terms)
    }
    
    init(terms: String) {
        self.terms.append(contentsOf: terms.components(separatedBy: " "))
    }
    
    func getResultsFrom(index: IndexProtocol) -> [QueryResult]? {
        var mergedResults: [QueryResult] = []

        guard let stemmer = PorterStemmer(withLanguage: .English) else {
            return nil
        }
        
        if let postings = index.getPostingsWithPositionsFor(stem: stemmer.stem(self.terms[0])) {
            mergedResults = convertToQueryResults(postings: postings, fromTerm: self.terms[0])
        }
        else {
            return nil
        }
        
        for i in 1 ..< self.terms.count {
            if let postings = index.getPostingsWithPositionsFor(stem: stemmer.stem(self.terms[i])) {
                let newResults = convertToQueryResults(postings: postings, fromTerm: self.terms[i])
                mergedResults = positionalMerge(left: mergedResults, right: newResults)
            }
            else {
                return nil
            }
        }
        return mergedResults
    }
    
    private func positionalMerge(left: [QueryResult], right: [QueryResult]) -> [QueryResult] {
        
        var queryResults = [QueryResult]()
        var i: Int = 0
        var j: Int = 0
        
        while i < left.count && j < right.count {
            if left[i].documentId == right[j].documentId {
                if isFollowed(left: left[i].posting, right: right[j].posting) {
                    right[j].addMatchingTerms(terms: left[i].matchingForTerms)
                    queryResults.append(right[j])
                }
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
    
    func isFollowed(left: Posting, right: Posting) -> Bool {
        var i: Int = 0
        var j: Int = 0
        
        while i < left.positions.count && j < right.positions.count {
            if left.positions[i] == right.positions[j] {
                i += 1
            }
            else if left.positions[i] > right.positions[j] {
                j += 1
            }
            else if left.positions[i] < right.positions[j] {
                if right.positions[j] - left.positions[i] == 1 {
                    return true
                }
                i += 1
            }
        }
        return false
    }
    
    func toString() -> String {
        return ""
    }
}
