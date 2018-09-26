//
//  AndQuery.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/16/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class AndQuery: QueryComponent {
    
    private var components: [QueryComponent]
    
    init(components: [QueryComponent]) {
        self.components = [QueryComponent]()
        self.components.append(contentsOf: components)
    }
    
    func getResultsFrom(index: Index) -> [Result]? {
        var mergedResults: [Result]
        
        if let newResults = self.components[0].getResultsFrom(index: index) {
            mergedResults = newResults
        }
        else {
            return nil
        }
        
        for i in 1 ..< self.components.count {
            if let newResults = self.components[i].getResultsFrom(index: index) {
               mergedResults = andMerge(left: mergedResults, right: newResults)
            }
            else {
                return nil
            }
        }
        return mergedResults
    }
    
    func andMerge(left: [Result], right: [Result]) -> [Result] {
        var i: Int = 0
        var j: Int = 0
        var ret = [Result]()
        
        while i < left.count && j < right.count {
            if left[i].documentId == right[j].documentId {
                left[i].addMatchingTerms(terms: right[j].matchingForTerms)
                ret.append(left[i])
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
    
    func toString() -> String {
        return ""
    }
}

