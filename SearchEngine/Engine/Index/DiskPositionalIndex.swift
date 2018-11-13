//
//  DiskPositionalIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskPositionalIndex<T: FixedWidthInteger, U: FixedWidthInteger>: IndexProtocol {
    /// An Utility class that allows writing index on disk files permanenty
    private var diskIndexUtility: ReadingDiskEnvUtility<T, U>
    /// An Index that holds all K-gram values
    private(set) var kGramIndex: GramIndex
    
    init(atPath url: URL, utility: ReadingDiskEnvUtility<T, U>, gramIndex: GramIndex) {
        self.diskIndexUtility = utility
        self.kGramIndex = gramIndex
    }
 
    /// Retrieve postings that contains a given stem
    ///
    /// - Parameter stem: Is the stemmed version of the term
    /// - Returns: A list of postings that contains the stem
    func getPostingsWithoutPositionsFor(stem: String) -> [Posting]? {
        return self.diskIndexUtility.getPostings(forTerm: stem, withPositions: false)
    }
    
    func getPostingsWithPositionsFor(stem: String) -> [Posting]? {
        return self.diskIndexUtility.getPostings(forTerm: stem, withPositions: true)
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
        return self.diskIndexUtility.getVocabulary()
    }
    
    /// Returns the K-Gram index
    ///
    /// - Returns: A K-Gram index object
    func getKGramIndex() -> GramIndexProtocol {
        return self.kGramIndex
    }

    func getElements() -> Set<VocabularyElement> {
        return Set<VocabularyElement>()
    }
    
    /// Release resources used by the index
    func dispose() {
        self.diskIndexUtility.dispose()
    }
}
