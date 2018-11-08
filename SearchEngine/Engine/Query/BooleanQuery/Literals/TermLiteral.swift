//
//  TermLiteral.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/16/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation
import PorterStemmer2

class TermLiteral: Queriable {

    var term: String
    
    init(term: String) {
        self.term = term
    }
    
    func getResultsFrom(index: IndexProtocol) -> [QueryResult]? {
        if let stemmer = PorterStemmer(withLanguage: .English) {
            let stem = stemmer.stem(self.term)
            if let postings = index.getPostingsWithoutPositionsFor(stem: stem) {
                return convertToQueryResults(postings: postings, fromTerm: self.term)
            }
            return nil
        }
        return nil
    }

    func toString() -> String {
        return term
    }
}
