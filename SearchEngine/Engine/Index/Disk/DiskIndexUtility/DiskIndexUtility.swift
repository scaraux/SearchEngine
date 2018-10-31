//
//  DiskIndexReader.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskIndexUtility<T: FixedWidthInteger, U: FixedWidthInteger> {
    
    private var postingsFile: BinaryFile
    private var vocabularyFile: BinaryFile
    private var tableFile: BinaryFile
    
    private var postingsUtility: DiskPostingsUtility<T>
    
    private var valueByteLength: Int
    private var url: URL

    init(atPath url: URL, fileMode mode: DiskConstants.FileDescriptorMode,
         postingsEncoding: T.Type, offsetsEncoding: U.Type) throws {
        
        self.url = url
        self.valueByteLength = MemoryLayout<U>.size
        
        self.postingsUtility = DiskPostingsUtility(type: postingsEncoding)
        
        let postingsFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.postingsDiskFileName)
        
        let vocabularyFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.vocabularyDiskFileName)
    
        let tableFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.tableDiskFileName)
        
        self.postingsFile = try BinaryFile.createBinaryFile(atPath: postingsFileURL, for: mode)
        self.vocabularyFile = try BinaryFile.createBinaryFile(atPath: vocabularyFileURL, for: mode)
        self.tableFile = try BinaryFile.createBinaryFile(atPath: tableFileURL, for: mode)
    }
    
    public func dispose() {
        self.postingsFile.dispose()
        self.vocabularyFile.dispose()
        self.tableFile.dispose()
    }
    
    private func writePostings(_ vocabulary: [String], _ index: IndexProtocol) -> [Int64] {
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
            self.postingsFile.write(data: data)
        }
        return self.postingsFile.offsets
    }
    
    private func writeVocabulary(_ vocabulary: [String]) -> [Int64] {
        // The data object that will hold the bytes to be written to the file
        var data: Data
        // Iterate over all terms in vocabulary
        for i in 0..<vocabulary.count {
            // Retrieve the term
            let term = vocabulary[i]
            // Convert string to utf8 data object
            data = term.data(using: .utf8)!
            // Write data object to file
            self.vocabularyFile.write(data: data)
        }
        return self.vocabularyFile.offsets
    }
    
    private func writeTable(_ vocabularyOffsets: [Int64], _ postingsOffsets: [Int64]) {
        for i in 0..<vocabularyOffsets.count {
            var termOffset: Int64 = vocabularyOffsets[i]
            let termOffsetData: Data =  Data(bytes: &termOffset, count: MemoryLayout.size(ofValue: termOffset))
            
            var postingOffset: Int64 = postingsOffsets[i]
            let postingOffsetData: Data =  Data(bytes: &postingOffset,
                                                count: MemoryLayout.size(ofValue: postingsOffsets))
            
            self.tableFile.write(data: termOffsetData)
            self.tableFile.write(data: postingOffsetData)
        }
    }
    
    private func binarySearchTerm(_ target: String) -> U {
        // The size of a complete chunk (two rows, 4 values)
        let chunkSize = self.valueByteLength * 2
        // Number of chunks in binary file, (total bytes divided by chunk size)
        let totalChunks: UInt64 = self.tableFile.size / UInt64(chunkSize)
        // Current term offset in vocabulary file, as Fixed Width Integer
        var termVocabOffset: U
        // Current term offset in postings file, as Fixed Width Integer
        var termPostingsOffset: U
        // Current term's next term offset in vocabulary file
        // as Fixed Width Integer, to calculate term size
        var nextTermOffset: U
        // Current term length
        var termLength: Int
        // A marker to beginning of file
        var startMarker: UInt64 = 0
        // A marker to end of file
        var endMarker: UInt64 = totalChunks - 1
        // The current chunk to read
        var chunk: Data
        // Iterate as long as there is space
        while startMarker <= endMarker {
            // Compute the middle offset in file
            let middle = (startMarker + endMarker) / 2
            // Read a chunk containing two terms
            chunk = tableFile.readAt(offset: middle * UInt64(chunkSize), chunkSize: chunkSize * 2)
            // Retrieve offset of term in vocabulary file
            termVocabOffset = chunk.subdata(in: 0..<self.valueByteLength).withUnsafeBytes { $0.pointee }
            // Retrieve offset of term's postings in postings file
            termPostingsOffset = chunk.subdata(in: self.valueByteLength..<chunkSize).withUnsafeBytes { $0.pointee }
            // Retrieve offset of next term
            // TODO: Handle last item
            nextTermOffset = chunk.subdata(in: (self.valueByteLength * 2)..<(chunkSize * 2))
                .withUnsafeBytes { $0.pointee }
            // Calculate term length by substracting next term offset to current term offset
            termLength = Int(nextTermOffset - termVocabOffset)
            // Read term in vocabulary file, from offset
            chunk = vocabularyFile.readAt(offset: UInt64(termVocabOffset), chunkSize: termLength)
            // Create a UTF-8 string representation of the term
            guard let term = String(bytes: chunk, encoding: .utf8) else {
                return -1
            }
            print("\(term) \(startMarker) \(endMarker)")
            // If term if target, return postings offset
            if term == target {
                return termPostingsOffset
            }
            // If target term is before term we found, we search in left part
            else if target < term {
                endMarker = middle - 1
            }
            // If target term is after term we found, we search in right part
            else {
                startMarker = middle + 1
            }
        }
        return -1
    }
    
    public func getPostings(forTerm term: String) {
        let postingsOffset: U = binarySearchTerm(term)
        if postingsOffset != -1 {
            print(postingsOffset)
        }
    }
    
    public func writeIndex(index: IndexProtocol) {
        let vocabulary: [String] = index.getVocabulary()
        let postingsOffsets: [Int64] = writePostings(vocabulary, index)
        let vocabularyOffsets: [Int64] = writeVocabulary(vocabulary)
        writeTable(vocabularyOffsets, postingsOffsets)
    }
}
