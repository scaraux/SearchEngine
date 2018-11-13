//
//  SpellingManager.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/12/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class SpellingManager {
    
    private var pool: [SpellingSuggestion]
    
    private init() {
        self.pool = []
    }
    
    static let shared = SpellingManager()
    
    public func hasSuggestions() -> Bool {
        return !self.pool.isEmpty
    }
    
    public func addSuggestion(_ suggestion: SpellingSuggestion) {
        self.pool.append(suggestion)
    }
    
    public func getSuggestions() -> [SpellingSuggestion] {
        let suggestions: [SpellingSuggestion] = pool
        pool.removeAll()
        return suggestions
    }
}
