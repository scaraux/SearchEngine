//
//  RankedQuery.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/4/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation
import SwiftPriorityQueue

class RankedQuery: Queriable {
    
    let index: IndexProtocol
    let terms: [String]
    
    init(withIndex index: IndexProtocol, bagOfWords: String) {
        self.index = index
        self.terms = bagOfWords.components(separatedBy: " ")
    }
    
    // TODO STEMS ?
    func getResultsFrom(index: IndexProtocol) -> [QueryResult]? {
        // Retrieve the total number of documents in Corpus
        let numberOfDocuments = DirectoryCorpus.shared.corpusSize
        // Create a dictionary of accumulators values, from document ids to accumulators
        var scores: [Int: DocumentScore] = [:]
        // Iterate over all terms in the query
        for term in terms {
            // Retrieve results that contains the term
            if let postings: [Posting] = index.getPostingsWithoutPositionsFor(stem: term) {
                // Calculate the number of documents that contains term
                let documentsContainingTerm: Int = postings.count
                // Calculate wqt
                let wqt = log(1 + Double(numberOfDocuments / documentsContainingTerm))
                // Iterate over all results that contains term
                for posting: Posting in postings {
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
        // TODO IF NOT ZERO ?
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
                let r = QueryResult(Posting(withDocumentId: score.documentId), terms: score.matchingTerms)
                // Append result
                results.append(r)
            }
        }
        // Return the results
        return results
    }
    
    func toString() -> String {
        return ""
    }
}
