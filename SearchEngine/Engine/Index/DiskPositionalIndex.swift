//
//  DiskPositionalIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskPositionalIndex<T: FixedWidthInteger, U: FixedWidthInteger>: IndexProtocol {

    /// An Index that holds all K-gram values
    private(set) var kGramIndex: GramIndex
    /// An Utility class that allows writing index on disk files permanenty
    private var diskIndexUtility: DiskEnvUtility<T, U>
    
    init(atPath url: URL, utility: DiskEnvUtility<T, U>) {
        self.kGramIndex = GramIndex()
        self.diskIndexUtility = utility
    }
    
    /// Retrieve postings that contains a given stem, as QueryResult
    /// object. QueryResults contains a given posting, and useful informations
    /// about the query, such as FileDocument, Terms etc...
    ///
    /// - Parameters:
    ///   - stem: Is the stemmed string corresponding to the term
    ///   - fromTerm: Is the raw term
    /// - Returns: A list of QueryResults
    func getQueryResultsFor(stem: String, fromTerm: String) -> [QueryResult]? {
        if let postings = self.diskIndexUtility.getPostings(forTerm: stem) {
            return postings.map({ QueryResult($0, term: fromTerm) })
        }
        return nil
    }
    
    /// Retrieve postings that contains a given stem
    ///
    /// - Parameter stem: Is the stemmed version of the term
    /// - Returns: A list of postings that contains the stem
    func getPostingsFor(stem: String) -> [Posting]? {
        return self.diskIndexUtility.getPostings(forTerm: stem)
    }
    
    /// Retrieve calculated weight for a given document
    ///
    /// - Parameter id: Is the document ID that identifies the docunent
    /// - Returns: Returns the weigth for the selected document
    func getWeightForDocument(documentId id: Int) -> Double? {
        return self.diskIndexUtility.getWeightForDocument(documentId: id)
    }
    
    /// Returns the all terms contained by the index
    ///
    /// - Returns: A list of terms, as strings
    func getVocabulary() -> [String] {
        return []
    }
    
    /// Returns the K-Gram index
    ///
    /// - Returns: A K-Gram index object
    func getKGramIndex() -> GramIndexProtocol {
        return self.kGramIndex
    }
    
    /// Release resources used by the index
    func dispose() {
        self.diskIndexUtility.dispose()
    }
}
