//
//  DiskIndexReader.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskIndexUtility<T: FixedWidthInteger, U: FixedWidthInteger> {
    // The Binary File that holds all the postings
    private var postingsFile: BinaryFile
    // The Binary File that holds all the terms aka vocabulary
    private var vocabularyFile: BinaryFile
    // The Binary File that associate offsets of term - postings
    private var tableFile: BinaryFile
    // The URL of the index directory
    private var url: URL

    init(atPath url: URL,
         fileMode mode: DiskConstants.FileDescriptorMode,
         postingsEncoding: T.Type,
         offsetsEncoding: U.Type) throws {
        // Set URL of index directory
        self.url = url
        // Construct Postings file URL
        let postingsFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.postingsDiskFileName)
        // Construct Vocabulary file URL
        let vocabularyFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.vocabularyDiskFileName)
        // Construct Table file URL
        let tableFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.tableDiskFileName)
        // Construct Binary Files
        
        if mode == .writing {
            self.postingsFile = try BinaryFile.createBinaryFile(atPath: postingsFileURL, for: mode)
            self.vocabularyFile = try BinaryFile.createBinaryFile(atPath: vocabularyFileURL, for: mode)
            self.tableFile = try BinaryFile.createBinaryFile(atPath: tableFileURL, for: mode)
        } else {
            self.postingsFile = try BinaryFile(atPath: postingsFileURL, for: mode)
            self.vocabularyFile = try BinaryFile(atPath: vocabularyFileURL, for: mode)
            self.tableFile = try BinaryFile(atPath: tableFileURL, for: mode)
        }
    }
    
    public func dispose() {
        self.postingsFile.dispose()
        self.vocabularyFile.dispose()
        self.tableFile.dispose()
    }
    
    /// Retrieve postings that corresponds to a given term, in the
    /// disk written index. A binary search is performed on the
    /// table binary file to locate the offset of the postings in
    /// the postings binary file. If offset exists, postings are
    /// translated from binary to an array of postings.
    ///
    /// - Parameter term: Is the term we need to find postings for
    /// - Returns: The list of postings corresponding to term
    public func getPostings(forTerm term: String) -> [Posting]? {
        // Locate postings offset for term, in postings binary file
        let result: (Bool, U) = binarySearchTerm(term)
        // If term exists in index
        if result.0 {
            // Retrieve posting offset
            let postingOffset = UInt64(result.1)
            // Retrieve and return postings at given offset
            return getPostingsAtOffset(atOffset: postingOffset, forTerm: term)
        }
        // Return nil if term has not been found
        return nil
    }
    
    public func writeIndex(index: IndexProtocol) {
        // Retrieve all terms in vocabulary, sorted alphabetically
        let vocabulary: [String] = index.getVocabulary()
        // Write all terms in vocabulary binary file, retrieve offsets
        let vocabularyOffsets: [Int64] = writeVocabulary(vocabulary)
        // Write all postings in postings binary file, retrieve offsets
        let postingsOffsets: [Int64] = writePostings(vocabulary, index)
        // Write pairs of offsets, for each term and its postings, in table binary file
        writeTable(vocabularyOffsets, postingsOffsets)
    }
}

extension DiskIndexUtility {
    
    private func getBinaryRepresentation(forPostings postings: [Posting]) -> Data {
        // A Integer byte array, of desired size T
        var bytes = [T]()
        // The frequency of the term within corpus, or how many documents contains it
        let dft: T = T(postings.count)
        // Add dft to array
        bytes.append(dft)
        // Iterate over all postings
        for posting in postings {
            // Convert Id of current document to Integer of desired size
            let id: T = T(posting.documentId)
            // Convert the frequency of the term within document to Integer of desired size
            let tftd: T = T(posting.positions.count)
            // Add id to array
            bytes.append(id) //.littleendian
            // Add tftd to array
            bytes.append(tftd) //.littleendian
            // Iterate over all positions
            for position in posting.positions {
                // Convert position to Integer of desired size
                let position: T = T(position)
                // Add position to array
                bytes.append(position) //.littleendian
            }
        }
        // Return bytes as Data object
        return Data(fromArray: bytes)
    }
    
    private func getPostingsAtOffset(atOffset offset: UInt64, forTerm term: String) -> [Posting] {
        // The array of postings that this function will translate form bytes
        var postings = [Posting]()
        // The number of bits to represent a single value
        let memorySizeOfValue = MemoryLayout<T>.size
        // A counter of documents
        var documentsCounter: Int = 0
        // A counter of positions, reset for each document
        var positionCounter: Int = 0
        // A buffer
        var data: Data
        // An Integer holding the frequency of term in corpus
        var dft: T = 0
        // An Integer holding the id of a document
        var id: T = 0
        // An Integer holding the frequency of term in document
        var tftd: T = 0
        // An Integer holding a position of term within document
        var position: T = 0
        // Read a first value from bytes, which will be dft
        data = self.postingsFile.readAt(offset: offset, chunkSize: memorySizeOfValue)
        // Convert byte to dft Integer of desired size
        dft = data.withUnsafeBytes { $0.pointee }
        // Reapeat until each document is translated
        repeat {
            // Read a byte that represents the document id
            data = self.postingsFile.read(chunkSize: memorySizeOfValue)
            // Convert byte to id Integer of desired size
            id = data.withUnsafeBytes { $0.pointee }
            // Create posting with document
            let posting = Posting(withDocumentId: Int(id), forTerm: term)
            // Read a byte that represents the number of positions in the document
            data = self.postingsFile.read(chunkSize: memorySizeOfValue)
            // Convert byte to tftd Integer of desired size
            tftd = data.withUnsafeBytes { $0.pointee }
            // Set positions counter to zero
            positionCounter = 0
            // Repeat until each position is translated
            repeat {
                // Read a byte that represents the position
                data = self.postingsFile.read(chunkSize: memorySizeOfValue)
                // Convert byte to position Integer of desired size
                position = data.withUnsafeBytes { $0.pointee }
                // Add position to posting
                posting.addPosition(Int(position))
                // Increment position counter
                positionCounter += 1
                
            } while positionCounter < tftd
            // Append posting to postings list
            postings.append(posting)
            // Increment document counter
            documentsCounter += 1
            
        } while documentsCounter < dft
        // Return the postings list
        return postings
    }
    
}

extension DiskIndexUtility {
    
    private func writePostings(_ vocabulary: [String], _ index: IndexProtocol) -> [Int64] {
        // Iterate over all terms in vocabulary
        for i in 0..<vocabulary.count {
            // Retrieve the term
            let term = vocabulary[i]
            // Retrive the postings list for the term
            guard let postings: [Posting] = index.getPostingsFor(stem: term) else {
                fatalError("Error while generating postings binary file.")
            }
            // Generate a binary representation of the term's postings list as a Data object
            let data: Data = getBinaryRepresentation(forPostings: postings)
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
}

extension DiskIndexUtility {
    
    private func binarySearchTerm(_ target: String) -> (Bool, U) {
        // Number of bits to represent a single value
        let memorySizeOfValue = MemoryLayout<U>.size
        // The size of a complete chunk (two rows, 4 values)
        let chunkSize = memorySizeOfValue * 2
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
            termVocabOffset = chunk.subdata(in: 0..<memorySizeOfValue).withUnsafeBytes { $0.pointee }
            // Retrieve offset of term's postings in postings file
            termPostingsOffset = chunk.subdata(in: memorySizeOfValue..<chunkSize).withUnsafeBytes { $0.pointee }
            // Retrieve offset of next term
            // TODO: Handle last item
            nextTermOffset = chunk.subdata(in: (memorySizeOfValue * 2)..<(chunkSize * 2))
                .withUnsafeBytes { $0.pointee }
            // Calculate term length by substracting next term offset to current term offset
            termLength = Int(nextTermOffset - termVocabOffset)
            // Read term in vocabulary file, from offset
            chunk = vocabularyFile.readAt(offset: UInt64(termVocabOffset), chunkSize: termLength)
            // Create a UTF-8 string representation of the term
            guard let term = String(bytes: chunk, encoding: .utf8) else {
                // If cannot create string, return false
                return (false, 0)
            }
            // If term if target, return postings offset
            if term == target {
                return (true, termPostingsOffset)
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
        // Return false in case term has not been found
        return (false, 0)
    }
}
