//
//  AndQuery.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/16/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class AndQuery: Queriable {

    private(set) var components: [Queriable]
    
    init(components: [Queriable]) {
        self.components = [Queriable]()
        self.components.append(contentsOf: components)
    }
    
    func getResultsFrom(index: IndexProtocol) -> [QueryResult]? {
        var mergedResults: [QueryResult]
        
        if let newResults = self.components[0].getResultsFrom(index: index) {
            mergedResults = newResults
        }
        else {
            return nil
        }
        
        for i in 1 ..< self.components.count {
            if let newResults = self.components[i].getResultsFrom(index: index) {
               mergedResults = intersection(left: mergedResults, right: newResults)
            }
            else {
                return nil
            }
        }
        return mergedResults
    }
    
    func intersection(left: [QueryResult], right: [QueryResult]) -> [QueryResult] {
        
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
        return ""
    }
}
