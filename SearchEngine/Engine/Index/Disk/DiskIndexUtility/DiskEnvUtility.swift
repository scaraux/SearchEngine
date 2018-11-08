//
//  DiskIndexReader.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskEnvUtility<T: FixedWidthInteger, U: FixedWidthInteger> {
    // The Binary File that holds wieghts for files
    private var weightsFile: BinaryFile
    // The Binary File that holds all the postings
    private var postingsFile: BinaryFile
    // The Binary File that holds all the terms aka vocabulary
    private var vocabularyFile: BinaryFile
    // The Binary File that associate offsets of term - postings
    private var tableFile: BinaryFile
    // The URL of the index directory
    private var url: URL
    // The size of an integer in the postings file
    private var sizeOfT = MemoryLayout<T>.size
    // The size of a Double
    private var sizeOfDouble = MemoryLayout<Double>.size
    
    var counter: Int = 0
    
    init(atPath url: URL,
         fileMode mode: DiskConstants.FileDescriptorMode,
         postingsEncoding: T.Type,
         offsetsEncoding: U.Type) throws {
        // Set URL of index directory
        self.url = url
        // Construct Weights file URL
        let weightsFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.weightsDiskFileName)
        // Construct Postings file URL
        let postingsFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.postingsDiskFileName)
        // Construct Vocabulary file URL
        let vocabularyFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.vocabularyDiskFileName)
        // Construct Table file URL
        let tableFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.tableDiskFileName)
        
        if mode == .writing {
            self.weightsFile = try BinaryFile.createBinaryFile(atPath: weightsFileURL, for: mode)
            self.postingsFile = try BinaryFile.createBinaryFile(atPath: postingsFileURL, for: mode)
            self.vocabularyFile = try BinaryFile.createBinaryFile(atPath: vocabularyFileURL, for: mode)
            self.tableFile = try BinaryFile.createBinaryFile(atPath: tableFileURL, for: mode)
        } else {
            self.weightsFile = try BinaryFile(atPath: weightsFileURL, for: mode)
            self.postingsFile = try BinaryFile(atPath: postingsFileURL, for: mode)
            self.vocabularyFile = try BinaryFile(atPath: vocabularyFileURL, for: mode)
            self.tableFile = try BinaryFile(atPath: tableFileURL, for: mode)
        }
    }
    
    public func dispose() {
        self.weightsFile.dispose()
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
    public func getPostings(forTerm term: String, withPositions: Bool) -> [Posting]? {
        // Locate postings offset for term, in postings binary file
        let result: (Bool, U) = binarySearchTerm(term)
        // If term exists in index
        if result.0 {
            // Retrieve posting offset
            let postingOffset = UInt64(result.1)
            // Retrieve and return postings at given offset
            let postings: [Posting] = getPostingsAtOffset(atOffset: postingOffset,
                                                          forTerm: term,
                                                          withPositions: withPositions)
            // Return postings
            return postings
        }
        // Return nil if term has not been found
        return nil
    }
    
    public func getWeightForDocument(documentId id: Int) -> Double? {
        // Calculate how many bytes needed to represent desired weight value
        let chunkSize = MemoryLayout<Double>.size
        // Calculate offset, knowing offset 0 is for id 1
        let offset = (UInt64(id - 1) * UInt64(chunkSize))
        // Seek to offset
        self.weightsFile.placeHeadAt(offset: offset)
        // Read bytes to data
        let data: Data = self.weightsFile.read(chunkSize: chunkSize)
        // Convert bytes to Double and return
        let weight: Double = data.withUnsafeBytes { $0.pointee }
        // Return weight
        return weight
    }
    
    /// Write weights for given documents. Documents are sorted in ascending
    /// order by their id. Therefore the offset corresponds to the document id.
    ///
    /// - Parameter documents: The documents whose weights will be written on disk
    public func writeWeights(documents: [DocumentProtocol]) {
        writeWeights(documents)
    }
    
    /// Write entire index to disk files, including file names,
    /// postings and positions
    ///
    /// - Parameter index: Is the index to be written
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

extension DiskEnvUtility {
    
    private func getBinaryRepresentation(forPostings postings: [Posting]) -> Data {
        // A Integer byte array, of desired size T
        var data = Data()
        // The frequency of the term within corpus, or how many documents contains it
        var dft: T = T(postings.count)
        // Add dft to array 
        data.append(Data(bytes: &dft, count: sizeOfT))
        // Iterate over all postings
        for posting in postings {
            // Retrieve ID of document
            var id: T = T(posting.documentId)
            // Add ID to array
            data.append(Data(bytes: &id, count: sizeOfT))
            // Retrieve wdt from document
            var wdt: Double = posting.calculateWdt()
            // Add wdt to array
            data.append(Data(bytes: &wdt, count: MemoryLayout<Double>.size))
            // Retrieve frequency
            var tftd: T = T(posting.frequency)
            // Add tftd to array
            data.append(Data(bytes: &tftd, count: sizeOfT))
            // Iterate over all positions
            for position in posting.positions {
                // Convert position to Integer of desired size
                var position: T = T(position)
                // Add position to array
                data.append(Data(bytes: &position, count: sizeOfT))
            }
        }
        // Return data
        return data
    }
    
    private func getPostingData(forTerm term: String, withPositions: Bool) -> Posting {
        // An Integer holding the id of a document
        let id: T = self.postingsFile.readInteger()!
        // An Double holding the wdt of document
        let wdt: Double = self.postingsFile.readDouble()!
        // An Integer holding the frequency of term in document
        let tftd: T = self.postingsFile.readInteger()!
        // Create posting with document
        let posting = Posting(withDocumentId: Int(id), forTerm: term)
        // Set wdt in posting
        posting.wdt = wdt
        // If we need positions in the posting
        if withPositions == true {
            // A counter of positions, reset for each document
            var positionCounter: Int = 0
            // Repeat until each position is translated
            repeat {
                let position: T = self.postingsFile.readInteger()!
                // Add position to posting
                posting.addPosition(Int(position))
                // Increment position counter
                positionCounter += 1
                
            } while positionCounter < tftd
        }
        // If we don't need positions in the posting
        else {
            // Get current offset
            let currentOffset = self.postingsFile.headOffset
            // Calculate offset after last position (nb of positions * their size)
            let lastPositionOffset = currentOffset + (UInt64(tftd) * UInt64(self.sizeOfT))
            // Seek to offset after positions
            self.postingsFile.placeHeadAt(offset: lastPositionOffset)
        }
        // Return posting
        return posting
    }
    
    private func getPostingsAtOffset(atOffset offset: UInt64, forTerm term: String, withPositions: Bool) -> [Posting] {
        // The array of postings that this function will translate form bytes
        var postings = [Posting]()
        // A counter of documents
        var documentsCounter: Int = 0
        // Seek to offset
        self.postingsFile.placeHeadAt(offset: offset)
        // Retrieve dft value, number of postings
        let dft: T = self.postingsFile.readInteger()!
        // Reapeat until each posting is translated
        repeat {
            // Retrieve posting
            let posting: Posting = getPostingData(forTerm: term, withPositions: withPositions)
            // Append posting to postings list
            postings.append(posting)
            // Increment document counter
            documentsCounter += 1
            
        } while documentsCounter < dft
        // Return the postings list
        return postings
    }
}

extension DiskEnvUtility {
    
    private func writeWeights(_ documents: [DocumentProtocol]) {
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
    
    private func writePostings(_ vocabulary: [String], _ index: IndexProtocol) -> [Int64] {
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

extension DiskEnvUtility {
    
    private func binarySearchTerm(_ target: String) -> (Bool, U) {
        // Number of bits to represent a single value
        let memorySizeOfValue = MemoryLayout<U>.size
        // The size of a complete chunk (two rows, 4 values)
        let chunkSize = memorySizeOfValue * 2
        // Number of chunks in binary file, (total bytes divided by chunk size)
        let totalChunks: UInt64 = self.tableFile.size / UInt64(chunkSize)
        // A marker to beginning of file
        var startMarker: UInt64 = 0
        // A marker to end of file
        var endMarker: UInt64 = totalChunks - 1
        // Iterate as long as there is space
        while startMarker <= endMarker {
            // Buffer to store term
            let termData: Data
            // Compute the middle offset in file
            let middle = (startMarker + endMarker) / 2
            // Seek to offset
            self.tableFile.placeHeadAt(offset: middle * UInt64(chunkSize))
            // Calculate term offset in vocabulary file
            let termVocabOffset: U = self.tableFile.readInteger()!
            // Calculate postings offset in postings file
            let termPostingsOffset: U = self.tableFile.readInteger()!
            // Calculate next term offset in vocabulary file
            if let nextTermOffset: U = self.tableFile.readInteger() {
                // Calculate term length by offsets difference
                let termLength = Int(nextTermOffset - termVocabOffset)
                // Seek to term position
                self.vocabularyFile.placeHeadAt(offset: UInt64(termVocabOffset))
                // Read term data to termLength
                termData = self.vocabularyFile.read(chunkSize: termLength)
            }
            else {
                // Read term data to EOF
                termData = self.vocabularyFile.readUntilEndOfFileAt(offset: UInt64(termVocabOffset))
            }
            // Create a UTF-8 string representation of the term
            guard let term = String(bytes: termData, encoding: .utf8) else {
                // If cannot create string, return false
                return (false, 0)
            }
            // If term if target, return postings offset
            if term == target {
                return (true, termPostingsOffset)
            }
            // If target term is before term we found, we search in left part
            else if target < term {
                if middle < 1 {
                    return (false, 0)
                }
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
