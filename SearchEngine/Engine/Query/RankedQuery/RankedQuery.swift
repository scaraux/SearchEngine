//
//  RankedQuery.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/4/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class RankedQuery: Queriable {
    
    let index: IndexProtocol
    let terms: [String]
    
    init(withIndex index: IndexProtocol, bagOfWords: String) {
        self.index = index
        self.terms = bagOfWords.components(separatedBy: " ")
    }
    
    func getResultsFrom(index: IndexProtocol) -> [QueryResult]? {
        // Retrieve the total number of documents in Corpus
        let numberOfDocuments = DirectoryCorpus.shared.corpusSize
        // Create a dictionary of accumulators, from document ids to ad values
        var accumulators: [Int: Double] = [:]
        // Iterate over all terms in the query
        for term in terms {
            // Retrieve results that contains the term
            if let results: [QueryResult] = index.getQueryResultsFor(stem: term, fromTerm: term) {
                // Calculate the number of documents that contains term
                let documentsContainingTerm: Int = results.count
                // Calculate wqt
                let wqt = log(1 + Double(numberOfDocuments / documentsContainingTerm))
                // Iterate over all results that contains term
                for result in results {
                    // Retrieve posting object
                    let posting = result.posting
                    // Retrieve current document ID
                    let documentId = posting.documentId
                    // Calculate wdt for result based on the frequency of term in document
                    let wdt = 1 + log(Double(posting.frequency))
                    // Add an acumulator value if does not exist
                    if accumulators[documentId] != nil {
                        accumulators[documentId]! += (wdt * wqt)
                    }
                    // Increase accumulator value if exsits
                    else {
                        accumulators[documentId] = (wdt * wqt)
                    }
                }
            }
            // Iterate over all accumulator values different than zero
            for accumulator in accumulators where accumulator.value != 0 {
                // Retrieve document ID which is the key
                let documentId = accumulator.key
                // Retrieve weight for document
                guard let weight = index.getWeightForDocument(documentId: documentId) else {
                    fatalError("Cannot find weight for document \(documentId)")
                }
                // Update accumulator
                accumulators[accumulator.key] = accumulator.value / weight
            }
        }
        // Return results ordered by score
        return nil
    }
    
    func toString() -> String {
        return ""
    }
}
