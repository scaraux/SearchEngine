//
//  DiskIndexWriter.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskIndexWriter: DiskIndexWriterProtocol {
    
    private var postingWriter: PostingWriterProtocol
    
    private struct Constants {
        static let indexDirectoryName = "index"
        static let postingsDiskFileName = "postings.bin"
        static let vocabularyDiskFileName = "vocab.bin"
        static let vocabTableDiskFileName = "vocab_table.bin"
    }
    
    init() {
        self.postingWriter = PostingWriter()
    }
    
    private func createFile(atPath url: URL) -> Bool {
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                var isDir: ObjCBool = true
                if !FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path, isDirectory: &isDir) {
                    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                }
                return FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
            } catch {
                return false
            }
        }
        return true
    }
    
    private func writePostings<T: FixedWidthInteger>(vocabulary: [String], url: URL, index: IndexProtocol) -> [T] {
        // The file handle to write data in file as OutputStream
        var fileHandle: FileHandle
        // The offset list that contains the positions for every representedterm
        var offsets: [T] = []
        // Current offset from byte zero
        var offsetFromZero: T = 0
        // The URL of the binary file that holds the postings data
        let postingsFileURL = url.appendingPathComponent(Constants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(Constants.postingsDiskFileName)
        // Check if the binary file exists or craete it
        guard createFile(atPath: postingsFileURL) else {
            fatalError("Could not open binary file to write postings.")
        }
        // Initialize the file handle to the file
        do {
            fileHandle = try FileHandle(forWritingTo: postingsFileURL)
        } catch {
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
            let binaryRepresentation: [Int32] = self.postingWriter.getBinaryRepresentation(forPostings: postings)
            // Convert integers to Data object
            data = Data(fromArray: binaryRepresentation)
            // Write data object to file
            fileHandle.write(data)
            // Append offset
            offsets.append(offsetFromZero)
            offsetFromZero += T(data.count)
        }
        // Close file
        fileHandle.closeFile()
        return offsets
    }
    
    private func writeVocabulary<T: FixedWidthInteger>(vocabulary: [String], url: URL) -> [T] {
        // The file handle to write data in file as OutputStream
        var fileHandle: FileHandle
        // The offset list that contains the positions for every representedterm
        var offsets: [T] = []
        // Current offset from byte zero
        var offsetFromZero: T = 0
        // The URL of the binary file that holds the postings data
        let vocabularyFileURL = url.appendingPathComponent(Constants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(Constants.vocabularyDiskFileName)
        // Check if the binary file exists or craete it
        guard createFile(atPath: vocabularyFileURL) else {
            fatalError("Could not open binary file to write postings.")
        }
        // Initialize the file handle to the file
        do {
            fileHandle = try FileHandle(forWritingTo: vocabularyFileURL)
        } catch {
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
            fileHandle.write(data)
            // Append offset
            offsets.append(offsetFromZero)
            offsetFromZero += T(data.count)
        }
        // Close file
        fileHandle.closeFile()
        return offsets
    }
    
    private func writeVocabTable<T: FixedWidthInteger>(vocabularyOffsets: [T], postingsOffsets: [T], url: URL) {
        // The file handle to write data in file as OutputStream
        var fileHandle: FileHandle
        // The URL of the binary file that holds the postings data
        let vocabTableFileURL = url.appendingPathComponent(Constants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(Constants.vocabTableDiskFileName)
        // Check if the binary file exists or craete it
        guard createFile(atPath: vocabTableFileURL) else {
            fatalError("Could not open binary file to write postings.")
        }
        // Initialize the file handle to the file
        do {
            fileHandle = try FileHandle(forWritingTo: vocabTableFileURL)
        } catch {
            fatalError("Could not open binary file to write postings.")
        }
        // Iterate over all terms in vocabulary
        for i in 0..<vocabularyOffsets.count {
            var wordGap = vocabularyOffsets[i].bigEndian
            var postingsGap = postingsOffsets[i].bigEndian
            let wordGapData = Data(bytes: &wordGap, count: MemoryLayout.size(ofValue: wordGap))
            let postingsGapData = Data(bytes: &postingsGap, count: MemoryLayout.size(ofValue: postingsGap))

            fileHandle.write(wordGapData)
            fileHandle.write(postingsGapData)
        }
        // Close file
        fileHandle.closeFile()
    }
    
    public func writeIndex(index: IndexProtocol, atPath url: URL) {
        let vocabulary: [String] = index.getVocabulary()
        
        let postingsOffsets: [Int32] = writePostings(vocabulary: vocabulary, url: url, index: index)
        let vocabularyOffsets: [Int32] = writeVocabulary(vocabulary: vocabulary, url: url)
        writeVocabTable(vocabularyOffsets: vocabularyOffsets, postingsOffsets: postingsOffsets, url: url)
    }
}
