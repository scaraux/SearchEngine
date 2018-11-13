//
//  RankedQuery.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/4/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation
import SwiftPriorityQueue
import PorterStemmer2

class RankedQuery: Queriable {
    
    private let index: IndexProtocol
    private var terms: [String]
    private let stemmer: PorterStemmer
    
    init(withIndex index: IndexProtocol, bagOfWords: String) {
        self.index = index
        self.terms = []
        self.stemmer = PorterStemmer(withLanguage: .English)!

        let gramIndex = index.getKGramIndex()
        let terms: [String] = bagOfWords.components(separatedBy: " ")
        for term in terms {
            if term.range(of: "*") != nil {
                if let candidates = gramIndex.getMatchingCandidatesFor(term: term) {
                    self.terms.append(contentsOf: candidates.map({ $0.stem }))
                }
            }
            else {
                self.terms.append(stemmer.stem(term))
            }
        }
    }
    
    func getResultsFrom(index: IndexProtocol) -> [QueryResult]? {
        // Create a dictionary of accumulators values, from document ids to accumulators
        var scores: [Int: DocumentScore] = [:]
        // Iterate over all terms in the query
        for term in terms {
            // Retrieve results that contains the term
            let postings: [Posting]? = index.getPostingsWithoutPositionsFor(stem: term)
            // Anticipate spelling correction
            if postings == nil || postings!.count < 1 {
                // Resolve suggestion
                if let suggestion: SpellingSuggestion = SpellingSuggestionFactory
                    .findSuggestion(forMispelledTerm: term, withIndex: index.getKGramIndex()) {
                    // Add suggestion to pool
                    SpellingManager.shared.addSuggestion(suggestion)
                }
            }
            if postings != nil {
                // Calculate wqt
                let wqt = log(1 + Double(DirectoryCorpus.shared.corpusSize / postings!.count))
                // Iterate over all results that contains term
                for posting: Posting in postings! {
                    // Retrieve current document ID
                    let documentId = posting.documentId
                    // Calculate wdt for result based on the frequency of term in document
                    let wdt = posting.wdt
                    // Add an acumulator value if does not exist
                    if scores[documentId] == nil {
                        scores[documentId] = DocumentScore(documentId: documentId)
                    }
                    // Increase accumulator value if exsits
                    scores[documentId]!.accumulator += (wdt * wqt)
                    scores[documentId]!.addMatchingTerm(term: term)
                } // End of results iteration
            }
        } // End of terms iteration
        // Return ranked documents from accumulator dictionary
        return rankResults(index: index, scores: scores)
    }
    
    private func rankResults(index: IndexProtocol, scores: [Int: DocumentScore]) -> [QueryResult]? {
        // The final results in ranked order
        var results: [QueryResult] = []
        // A priority queue to sort documents scores
        var priorityQueue = PriorityQueue<DocumentScore>()
        // Iterate over all dictionary entries
        for score: DocumentScore in scores.values where score.accumulator != 0 {
            // Retrieve weight for document, or failure
            guard let weight = index.getWeightForDocument(documentId: score.documentId) else {
                fatalError("Cannot find weight for document \(score.documentId)")
            }
            // Divide final accumulator value by weight
            score.score = score.accumulator / weight
            // Push score into priority queue
            priorityQueue.push(score)
        } // End of dictionary iteration
        // Return results ordered by score
        // Repeat N times
        for _ in 0..<10 {
            // Pop highest score from priority queue
            if let score: DocumentScore = priorityQueue.pop() {
                // Retrieve document that belongs to score
                let queryResult = QueryResult(Posting(withDocumentId: score.documentId), terms: score.matchingTerms)
                // Set score
                queryResult.score = score.score
                // Append result
                results.append(queryResult)
            }
        }
        // Return the results
        return results
    }
    
    func toString() -> String {
        return ""
    }
}
