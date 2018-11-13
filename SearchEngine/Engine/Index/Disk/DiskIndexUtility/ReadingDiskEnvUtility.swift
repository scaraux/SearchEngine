//
//  ReadingDiskEnvUtility.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/11/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation

extension Data {
    
    mutating func readData(ofLength length: Int) -> Data {
        let data: Data = self.subdata(in: 0..<length)
        self.removeSubrange(0..<length)
        return data
    }
}

class ReadingDiskEnvUtility<T: FixedWidthInteger, U: FixedWidthInteger>: DiskEnvUtility<T, U> {

    var map: [String: Set<VocabularyElement>] = [:]
    weak var loadDelegate: LoadEnvironmentDelegate?
    
    private func withTypes<R>(forGram gram: String,
                              mutations: (inout Set<VocabularyElement>) throws -> R) rethrows -> R {
        return try mutations(&map[gram, default: []])
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
    
    public func getVocabulary() -> [String] {
        var vocabulary: [String] = []
        var tableData: Data = Data()
        var vocabData: Data = Data()
        let sizeOfOffset =  MemoryLayout<UInt64>.size
        
        do {
            tableData = try Data(contentsOf: self.tableFile.url)
            vocabData = try Data(contentsOf: self.vocabularyFile.url)
        } catch {
            return []
        }
        // Initialize index
        var index = 0
        // Read the first offset
        var currentTermOffset: UInt64 = tableData.subdata(in: index..<index + 8).withUnsafeBytes { $0.pointee }
        
        while true {
            // If last term, stop loop
            if tableData.count < index + sizeOfOffset * 2 + sizeOfOffset {
                break
            }
            // Calculate start range for next offset
            let rangeStart = index + sizeOfOffset * 2
            // Calculate end range for next offset
            let rangeEnd = rangeStart + sizeOfOffset
            // Calculate next term offset
            let nextTermOffset: UInt64 = tableData.subdata(in: rangeStart..<rangeEnd).withUnsafeBytes { $0.pointee }
            // Increment position
            index += sizeOfOffset * 2
            // Calculate term length, by substracting offsets
            let termLength = nextTermOffset - currentTermOffset
            // Calculate term data start range
            let termDataRangeStart = Int(currentTermOffset)
            // Calculate term data end renage
            let termDataRangeEnd = termDataRangeStart + Int(termLength)
            // Retrieve term data
            let termData: Data = vocabData.subdata(in: termDataRangeStart..<termDataRangeEnd)
            // Append string to vocabulary
            vocabulary.append(String(bytes: termData, encoding: .utf8)!)
            // Set current term offset to next
            currentTermOffset = nextTermOffset
        }
        // Return vocabulary
        return vocabulary
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
    
    public func getGramMap() -> [String: Set<VocabularyElement>] {
        DispatchQueue.main.async {
            self.loadDelegate?.onLoadingPhaseChanged(phase: .phaseLoadingGrams, withTotalCount: 0)
        }
        
        var gramFileData: Data = Data()
        var stemsFileData: Data = Data()
        var typesFileData: Data = Data()

        do {
            gramFileData = try Data(contentsOf: self.gramFile.url)
            stemsFileData = try Data(contentsOf: self.vocabularyFile.url)
            typesFileData = try Data(contentsOf: self.typesFile.url)

        } catch {
            return [:]
        }
        
        var gramCounter = 1
        var index = 0
        // Iterate until we reach end of file
        while true {
            if gramFileData.count < index + 4 {
                break
            }
            let gramLength: UInt32 = gramFileData.subdata(in: index..<index + 4).withUnsafeBytes { $0.pointee }
            index += 4
            let gramData: Data = gramFileData.subdata(in: index..<index + Int(gramLength))
            index += Int(gramLength)
            // Convert gram data to UTF-8 String
            let gram: String = String(bytes: gramData, encoding: .utf8)!
            // Retrieve the number of types for the current gram
            let numberOfTypes: UInt32 = gramFileData.subdata(in: index..<index + 4).withUnsafeBytes { $0.pointee }
            index += 4
            // Initialize a type counter
            var typeCounter: Int = 0
            // Repear for each type
            repeat {
                let stemOffset: UInt64 = gramFileData.subdata(in: index..<index + 8).withUnsafeBytes { $0.pointee }
                index += 8
                let stemLength: UInt32 = gramFileData.subdata(in: index..<index + 4).withUnsafeBytes { $0.pointee }
                index += 4
                let typeOffset: UInt64 = gramFileData.subdata(in: index..<index + 8).withUnsafeBytes { $0.pointee }
                index += 8
                let typeLength: UInt32 = gramFileData.subdata(in: index..<index + 4).withUnsafeBytes { $0.pointee }
                index += 4
                
                let stemData: Data = stemsFileData.subdata(in: Int(stemOffset)..<Int(stemOffset) + Int(stemLength))
                let typeData: Data = typesFileData.subdata(in: Int(typeOffset)..<Int(typeOffset) + Int(typeLength))
                
                let stem: String = String(bytes: stemData, encoding: .utf8)!
                let type: String = String(bytes: typeData, encoding: .utf8)!

                let element = VocabularyElement(type: type, stem: stem)
                _ = withTypes(forGram: gram) { types in
                    types.insert(element)
                }
                if gramCounter % 250 == 0 {
                    DispatchQueue.main.async {
                        self.loadDelegate?.onLoadingTypes(forGram: gram, gramNb: gramCounter, totalGrams: 0)
                    }
                }
                // Increment type counter
                typeCounter += 1
            } while typeCounter < numberOfTypes
            // Increment gram counter
            gramCounter += 1
        }
        return self.map
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
            // The last gap for position
            var lastPositionGap: T = 0
            // A counter of positions, reset for each document
            var positionCounter: Int = 0
            // Repeat until each position is translated
            repeat {
                let position: T = self.postingsFile.readInteger()!
                // Add position to posting
                posting.addPosition(Int(position + lastPositionGap))
                // Increment position counter
                positionCounter += 1
                // Update last position gap
                lastPositionGap += position

            } while positionCounter < tftd
        }
        // If we don't need positions in the posting
        else {
            // Get current offset
            let currentOffset = self.postingsFile.getOffset()
            // Calculate offset after last position (nb of positions * their size)
            let lastPositionOffset = currentOffset + (UInt64(tftd) * UInt64(MemoryLayout<T>.size))
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
                return (false, 0)
            }
            // If term if target, return postings offset
            if term == target {
                return (true, termPostingsOffset)
            }
            // If target term is before term we found, we search in left part
            else if target < term {
                if middle < 1 { return (false, 0) }
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
