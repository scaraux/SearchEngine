//
//  SpellingSuggestion.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/12/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

struct SpellingSuggestion {
    
    var mispelledTerm: String
    var suggestedTerm: String
    var editDistance: Int = 0

    init(mispelledTerm: String, suggestedTerm: String) {
        self.mispelledTerm = mispelledTerm
        self.suggestedTerm = suggestedTerm
    }
}
