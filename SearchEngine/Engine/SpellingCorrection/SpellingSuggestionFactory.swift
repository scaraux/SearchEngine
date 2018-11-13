//
//  SpellingSuggestionFactory.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/13/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class SpellingSuggestionFactory {
    
    static func findSuggestion(forMispelledTerm term: String,
                               withIndex index: GramIndexProtocol) -> SpellingSuggestion? {
        // Retrieve similar terms
        guard let results: [VocabularyElement] = index.getSimilarCandidatesFor(term: term) else {
            return nil
        }
        // Initialize a candidate term
        var candidate: String = ""
        // Initialize a minimum edit distance value
        var minimumEditDistance: Int = 20000
        // Iterate over all results
        for result in results {
            // Retrieve type
            let type: String = result.type
            // Check if type is same as term
            if type == term {
                continue
            }
            // Calculate jaccard coefficient from type to mispelled term
            let jaccardForType = term.jaccardCoefficient(other: type)
            // If jaccard coefficient exceeds threshold
            if jaccardForType > 0.6 {
                // Calculate edit distance
                let editDistance = type.minimumEditDistance(other: term)
                // If edit distance is lower than current minimum edit distance
                if editDistance < minimumEditDistance {
                    // Set candidate to type
                    candidate = type
                    // Update minimum edit distance
                    minimumEditDistance = editDistance
                }
            }
        }
        // If no candidate matching thresolds, return nil
        if candidate.isEmpty {
            return nil
        }
        // Return result as a Spelling Correction object
        var result = SpellingSuggestion(mispelledTerm: term, suggestedTerm: candidate)
        // Set edit distance value for information
        result.editDistance = minimumEditDistance
        // Return result
        return result
    }
}
