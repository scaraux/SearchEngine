//
//  WritingDiskEnvUtility.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/11/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class WritingDiskEnvUtility<T: FixedWidthInteger, U: FixedWidthInteger>: DiskEnvUtility<T, U> {
    
    // Mapping for vocabulary
    public var mappings: [String: VocabularyMappingEntry]?
    
    /// Write entire index to disk files, including file names,
    /// postings and positions
    ///
    /// - Parameter index: Is the index to be written
    public func writeIndex(index: IndexProtocol) {
        // Retrieve all terms in vocabulary, sorted alphabetically
        let vocabulary: [String] = index.getVocabulary()
        // Write all terms in vocabulary binary file, retrieve offsets
        let vocabularyOffsets: [UInt64] = writeVocabulary(vocabulary)
        // Write all postings in postings binary file, retrieve offsets
        let postingsOffsets: [UInt64] = writePostings(vocabulary, index)
        // Write pairs of offsets, for each term and its postings, in table binary file
        writeTable(vocabularyOffsets, postingsOffsets)
    }
    
    public func writeKGramIndex(index gramIndex: GramIndexProtocol) {
        // Retrieve index
        guard let index = gramIndex as? GramIndex else {
            return
        }
        // Iterate over all entries in the gram index
        for entry in index.map {
            writeGram(gram: entry.key, types: entry.value)
        }
    }
    
    /// Write weights for given documents. Documents are sorted in ascending
    /// order by their id. Therefore the offset corresponds to the document id.
    ///
    /// - Parameter documents: The documents whose weights will be written on disk
    public func writeWeights(documents: [DocumentProtocol]) {
        // Retrieve documents sorted by document iD
        let documents = documents.sorted(by: { $0.documentId < $1.documentId })
        // Initialize a list of weigths
        var weights: [Double] = []
        // Iterate over all documents and append their weigth
        for document in documents {
            weights.append(document.weight)
        }
        // Create data from the array of weigths
        let data: Data = Data(fromArray: weights)
        // Write the entire object
        self.weightsFile.write(data: data)
    }
    
    private func getBinaryRepresentation(forPostings postings: [Posting]) -> Data {
        // A Data object that will be written on file
        var data = Data()
        // The frequency of the term within corpus, or how many documents contains it
        var dft: T = T(postings.count)
        // Add dft to array
        data.append(Data(bytes: &dft, count: MemoryLayout<T>.size))
        // Iterate over all postings
        for posting in postings {
            // Retrieve ID of document
            var id: T = T(posting.documentId)
            // Add ID to array
            data.append(Data(bytes: &id, count: MemoryLayout<T>.size))
            // Retrieve wdt from document
            var wdt: Double = posting.calculateWdt()
            // Add wdt to array
            data.append(Data(bytes: &wdt, count: MemoryLayout<Double>.size))
            // Retrieve frequency
            var tftd: T = T(posting.frequency)
            // Add tftd to array
            data.append(Data(bytes: &tftd, count: MemoryLayout<T>.size))
            // Initialize the last position gap
            var lastPositionGap: T = 0
            // Iterate over all positions
            for position in posting.positions {
                // Convert position to Integer of desired size
                let position: T = T(position)
                // Calculate gap
                var gap: T = position - lastPositionGap
                // Add position to array
                data.append(Data(bytes: &gap, count: MemoryLayout<T>.size))
                // Update last
                lastPositionGap += gap
            }
        }
        // Return data
        return data
    }
    
    private func writePostings(_ vocabulary: [String], _ index: IndexProtocol) -> [UInt64] {
        // Iterate over all terms in vocabulary
        for i in 0..<vocabulary.count {
            // Retrieve the term
            let term = vocabulary[i]
            // Retrive the postings list for the term
            guard let postings: [Posting] = index.getPostingsWithPositionsFor(stem: term) else {
                fatalError("Error while generating postings binary file.")
            }
            // Generate a binary representation of the term's postings list as a Data object
            let data: Data = getBinaryRepresentation(forPostings: postings)
            // Write data object to file
            self.postingsFile.write(data: data)
        }
        return self.postingsFile.offsets
    }
    
    private func writeVocabulary(_ vocabulary: [String]) -> [UInt64] {
        // Initialize a Vocabulary Mapping Entry dictionary
        var mappings: [String: VocabularyMappingEntry] = [:]
        // The data object that will hold the bytes to be written to the file
        var data: Data
        // Iterate over all terms in vocabulary
        for i in 0..<vocabulary.count {
            // Retrieve the term
            let term = vocabulary[i]
            // Convert string to utf8 data object
            data = term.data(using: .utf8)!
            // Add a Vocabulary Mapping Entry
            if mappings[term] == nil {
                let currentOffset: UInt64 = self.vocabularyFile.getOffset()
                let termUtf8LengthInBytes = data.count
                mappings[term] = VocabularyMappingEntry(atOffset: currentOffset, ofLength: termUtf8LengthInBytes)
            }
            // Write data object to file
            self.vocabularyFile.write(data: data)
        }
        // Set Mappings
        self.mappings = mappings
        // Return offsets
        return self.vocabularyFile.offsets
    }
    
    private func writeTable(_ vocabularyOffsets: [UInt64], _ postingsOffsets: [UInt64]) {
        for i in 0..<vocabularyOffsets.count {
            var termOffset: UInt64 = vocabularyOffsets[i]
            let termOffsetData: Data =  Data(bytes: &termOffset, count: MemoryLayout<UInt64>.size)
            
            var postingOffset: UInt64 = postingsOffsets[i]
            let postingOffsetData: Data =  Data(bytes: &postingOffset, count: MemoryLayout<UInt64>.size)
            
            self.tableFile.write(data: termOffsetData)
            self.tableFile.write(data: postingOffsetData)
        }
    }
    
    private func writeGram(gram: String, types: Set<String>) {
        // Retrieve mappings
        guard let mappings = self.mappings else {
            return
        }
        // A Data object that will be written on file
        var data = Data()
        // Convert gram to utf8 data object
        let gramAsUtf8Data: Data = gram.data(using: .utf8)!
        // Retrieve gram data length
        var gramDataLengthInBytes: T = T(gramAsUtf8Data.count)
        // Retrieve number of types for the gram
        var numberOfTypes: T = T(types.count)
        // Append Length of gram
        data.append(Data(bytes: &gramDataLengthInBytes, count: MemoryLayout<T>.size))
        // Append Gram data
        data.append(gramAsUtf8Data)
        // Append Number of types
        data.append(Data(bytes: &numberOfTypes, count: MemoryLayout<T>.size))
        // Iterate over all types
        for type in types {
            // Mapping entry for type
            let mappingEntry: VocabularyMappingEntry = mappings[type]!
            // Retrieve offset
            var offset: UInt64 = mappingEntry.offset
            // Retrieve length
            var length: T = T(mappingEntry.dataLength)
            // Append offset to data
            data.append(Data(bytes: &offset, count: MemoryLayout<UInt64>.size))
            // Append length to data
            data.append(Data(bytes: &length, count: MemoryLayout<T>.size))
        }
        // Write data
        self.gramFile.write(data: data)
    }
}
