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
    
    private func writePostings(vocabulary: [String], url: URL, index: IndexProtocol) -> [Int] {
        // The file handle to write data in file as OutputStream
        var fileHandle: FileHandle
        // The offset list that contains the positions for every representedterm
        var offsets: [Int] = [0]
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
            // If not first term, append offset
            if i != 0 {
                offsets.append(data.count)
            }
        }
        // Close file
        fileHandle.closeFile()
        return offsets
    }
    
    private func writeVocabulary(vocabulary: [String], url: URL) -> [Int] {
        // The file handle to write data in file as OutputStream
        var fileHandle: FileHandle
        // The offset list that contains the positions for every representedterm
        var offsets: [Int] = [0]
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
            // If not first term, append offset
            if i != 0 {
                offsets.append(data.count)
            }
        }
        // Close file
        fileHandle.closeFile()
        return offsets
    }
    
    public func writeIndex(index: IndexProtocol, atPath url: URL) {
        let vocabulary: [String] = index.getVocabulary()
        
        let postingsOffsets: [Int] = writePostings(vocabulary: vocabulary, url: url, index: index)
        let vocabularyOffsets: [Int] = writeVocabulary(vocabulary: vocabulary, url: url)
    }
}
