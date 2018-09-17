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
    
    func getPostingsFor(index: Index) -> [Posting]? {
        return nil
    }
    
    func toString() -> String {
        return ""
    }
    
}
