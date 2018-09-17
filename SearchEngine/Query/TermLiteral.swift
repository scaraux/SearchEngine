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
    
    func getPostingsFor(index: Index) -> [Posting]? {
        return index.getPostingsFor(term: term)
    }
    
    func toString() -> String {
        return term
    }
}
