//
//  DiskIndexReader.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DiskIndexReader {
    
    private var postings: BinaryFile
    private var vocabulary: BinaryFile
    private var table: BinaryFile
    
    init(atPath url: URL) throws {
        
        let postingsFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.postingsDiskFileName)
        
        let vocabularyFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.vocabularyDiskFileName)
    
        let tableFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.tableDiskFileName)
        
        try postings = BinaryFile(atPath: postingsFileURL)
        try vocabulary = BinaryFile(atPath: vocabularyFileURL)
        try table = BinaryFile(atPath: tableFileURL)
    }
    
    deinit {
        self.postings.dispose()
        self.vocabulary.dispose()
        self.table.dispose()
    }
    
    public func getPostings(forTerm term: String) {
//        binarySearchTerm(term)
        
        table.read(chunkSize: 4096)
    }
    
    private func binarySearchTerm(_ term: String) -> Int64 {
        var len: UInt64 = self.table.size / 16
        var startMarker: UInt64 = 0
        var endMarker: UInt64 = len - 1
        
//        while startMarker <= endMarker {
            let middle = (startMarker + endMarker) / 2
        
            table.move(toOffset: middle)
            let data: Data = table.read(chunkSize: 16)

            var offset : UInt32 = data.withUnsafeBytes { $0.pointee }
            
            print(offset)
//        }
        
        
        return 0
    }
}
