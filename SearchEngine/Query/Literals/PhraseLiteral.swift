//
//  PhraseLiteral.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/16/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class PhraseLiteral: QueryComponent {

    private var terms: [String] = [String]()
    
    init(terms: [String]) {
        self.terms.append(contentsOf: terms)
    }
    
    init(terms: String) {
        self.terms.append(contentsOf: terms.components(separatedBy: " "))
    }
    
    func getResultsFrom(index: Index) -> [Result]? {
        var mergedResults: [Result]

        if let newResults = index.getResultsFor(term: terms[0]) {
            mergedResults = newResults
        }
        else {
            return nil
        }
        
        for i in 1 ..< self.terms.count {
            if let newResults = index.getResultsFor(term: terms[i]) {
                mergedResults = positionalMerge(left: mergedResults, right: newResults)
            }
            else {
                return nil
            }
        }
        
        return mergedResults
    }
    
    func positionalMerge(left: [Result], right: [Result]) -> [Result] {
        var i: Int = 0
        var j: Int = 0
        var ret = [Result]()
        
        while i < left.count && j < right.count {
            if left[i].documentId == right[j].documentId {
                if isFollowed(left: left[i].posting, right: right[i].posting) {
                    right[j].addMatchingTerms(terms: left[i].matchingForTerms)
                    ret.append(right[j])
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
        return ret
    }
    
    func isFollowed(left: Posting, right: Posting) -> Bool {
        var i: Int = 0
        var j: Int = 0
        
        while i < left.positions.count && j < right.positions.count {
            print("\(left.positions[i]) \(right.positions[j])")
            if left.positions[i] == right.positions[j] {
                i += 1
            }
            else if left.positions[i] > right.positions[j] {
                if left.positions[i] - right.positions[j] == 1 {
                    return true
                }
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
