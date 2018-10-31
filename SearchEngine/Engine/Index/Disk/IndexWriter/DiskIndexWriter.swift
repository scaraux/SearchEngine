//
//  DiskIndexWriter.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskIndexWriter<T: FixedWidthInteger>: DiskIndexWriterProtocol {
    
    private var postingsUtility: PostingsDiskUtility<T>
    
    init(usingEncoding integerType: T.Type) {
        self.postingsUtility = PostingsDiskUtility(type: integerType)
    }
    
    public func writeIndex(index: IndexProtocol, atPath url: URL) {
        let vocabulary: [String] = index.getVocabulary()
        let postingsOffsets: [Int64] = writePostings(vocabulary, url, index)
        let vocabularyOffsets: [Int64] = writeVocabulary(vocabulary, url)
        writeTable(vocabularyOffsets, postingsOffsets, url)
    }
    
    private func writePostings(_ vocabulary: [String], _ url: URL, _ index: IndexProtocol) -> [Int64] {
        // The URL of the binary file that holds the postings data
        let finalURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.postingsDiskFileName)
        // Create binary file
        guard let binaryFile = BinaryFile.createBinaryFile(atPath: finalURL, for: .writing) else {
            fatalError("Could not open binary file to write postings.")
        }
        // The data object that will hold the bytes to be written to the file
        var data: Data
        // Iterate over all terms in vocabulary
        for i in 0..<vocabulary.count {
            // Retrieve the term
            let term = vocabulary[i]
            // Retrive the postings list for the term
            guard let postings: [Posting] = index.getPostingsFor(stem: term) else {
                fatalError("Error while generating postings binary file.")
            }
            // Generate a binary representation of the term's postings list with 4 bytes integer list
            let binaryRepresentation: [T] = self.postingsUtility.getBinaryRepresentation(forPostings: postings)
            // Convert integers to Data object
            data = Data(fromArray: binaryRepresentation)
            // Write data object to file
            binaryFile.write(data: data)
        }
        // Close file
        binaryFile.dispose()
        return binaryFile.offsets
    }
    
    private func writeVocabulary(_ vocabulary: [String], _ url: URL) -> [Int64] {
        // The URL of the binary file that holds the postings data
        let finalURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.vocabularyDiskFileName)
        // Create binary file
        guard let binaryFile = BinaryFile.createBinaryFile(atPath: finalURL, for: .writing) else {
            fatalError("Could not open binary file to write postings.")
        }
        // The data object that will hold the bytes to be written to the file
        var data: Data
        // Iterate over all terms in vocabulary
        for i in 0..<vocabulary.count {
            // Retrieve the term
            let term = vocabulary[i]
            // Convert string to utf8 data object
            data = term.data(using: .utf8)!
            // Write data object to file
            binaryFile.write(data: data)
        }
        // Close file
        binaryFile.dispose()
        return binaryFile.offsets
    }
    
    private func writeTable(_ vocabularyOffsets: [Int64], _ postingsOffsets: [Int64], _ url: URL) {
        // The URL of the binary file that holds the postings data
        let finalURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.tableDiskFileName)
        // Create binary file
        guard let binaryFile = BinaryFile.createBinaryFile(atPath: finalURL, for: .writing) else {
            fatalError("Could not open binary fi le to write postings.")
        }
        
        for i in 0..<vocabularyOffsets.count {
            var termOffset: Int64 = vocabularyOffsets[i]
            let termOffsetData: Data =  Data(bytes: &termOffset, count: MemoryLayout.size(ofValue: termOffset))

            var postingOffset: Int64 = postingsOffsets[i]
            let postingOffsetData: Data =  Data(bytes: &postingOffset,
                                                count: MemoryLayout.size(ofValue: postingsOffsets))

            binaryFile.write(data: termOffsetData)
            binaryFile.write(data: postingOffsetData)
        }
        // Close file
        binaryFile.dispose()
    }
}
