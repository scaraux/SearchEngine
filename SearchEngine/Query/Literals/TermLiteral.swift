//
//  TermLiteral.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/16/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class TermLiteral: QueryComponent {
    
    var term: String
    
    init(term: String) {
        self.term = term
    }
    
    func getResultsFrom(index: Index) -> [Result]? {
        var results = [Result]()
        if let postings = index.getPostingsFor(term: term) {
            for posting in postings {
                let result = Result(posting)
                results.append(result)
            }
            return results
        }
        return nil
    }
    
    func toString() -> String {
        return term
    }
}
