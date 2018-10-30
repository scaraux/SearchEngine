//
//  DiskIndexReader.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskIndexReader<T: FixedWidthInteger> {
    
    private var postings: BinaryFile
    private var vocabulary: BinaryFile
    private var table: BinaryFile
    private var valueByteLength: Int
    private var url: URL

    init(atPath url: URL, offsetsEncodedWithType type: T.Type) throws {
        
        self.url = url
        self.valueByteLength = MemoryLayout<T>.size
        
        let postingsFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.postingsDiskFileName)
        
        let vocabularyFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.vocabularyDiskFileName)
    
        let tableFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.tableDiskFileName)
        
        try self.postings = BinaryFile(atPath: postingsFileURL)
        try self.vocabulary = BinaryFile(atPath: vocabularyFileURL)
        try self.table = BinaryFile(atPath: tableFileURL)
    }
    
    deinit {
        self.postings.dispose()
        self.vocabulary.dispose()
        self.table.dispose()
    }
    
    public func getPostings(forTerm term: String) {
        let postingsOffset: T = binarySearchTerm(term)
        if postingsOffset != -1 {
            print(postingsOffset)
        }
    
    }
    
    private func binarySearchTerm(_ target: String) -> T {
        // The size of a complete chunk (two rows, 4 values)
        let chunkSize = self.valueByteLength * 2
        // Number of chunks in binary file, (total bytes divided by chunk size)
        let totalChunks: UInt64 = self.table.size / UInt64(chunkSize)
        // Current term offset in vocabulary file, as Fixed Width Integer
        var termVocabOffset: T
        // Current term offset in postings file, as Fixed Width Integer
        var termPostingsOffset: T
        // Current term's next term offset in vocabulary file
        // as Fixed Width Integer, to calculate term size
        var nextTermOffset: T
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
            chunk = table.readAt(offset: (middle - 1) * UInt64(chunkSize), chunkSize: chunkSize * 2)
            // Retrieve offset of term in vocabulary file
            termVocabOffset = chunk.subdata(in: 0..<self.valueByteLength).withUnsafeBytes { $0.pointee }
            // Retrieve offset of term's postings in postings file
            termPostingsOffset = chunk.subdata(in: self.valueByteLength..<chunkSize).withUnsafeBytes { $0.pointee }
            // Retrieve offset of next term
            nextTermOffset = chunk.subdata(in: (self.valueByteLength * 2)..<(chunkSize*2)).withUnsafeBytes { $0.pointee }
            // Calculate term length by substracting next term offset to current term offset
            termLength = Int(nextTermOffset - termVocabOffset)
            // Read term in vocabulary file, from offset
            chunk = vocabulary.readAt(offset: UInt64(termVocabOffset), chunkSize: termLength)
            // Create a UTF-8 string representation of the term
            guard let term = String(bytes: chunk, encoding: .utf8) else {
                return -1
            }
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
}
