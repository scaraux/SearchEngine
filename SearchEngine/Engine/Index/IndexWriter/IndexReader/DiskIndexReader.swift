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
    
    private var url: URL
    
    init(atPath url: URL) throws {
        
        self.url = url
        
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
        binarySearchTerm(term)
    }
    
    private func binarySearchTerm(_ term: String) -> Int64 {
        var len: UInt64 = self.table.size / 16
        var startMarker: UInt64 = 0
        var endMarker: UInt64 = len - 1
        
//        while startMarker <= endMarker {
            let middle = (startMarker + endMarker) / 2
        
            table.move(toOffset: (len - 1) * 16)
            let data: Data = table.read(chunkSize: 16)
        
            let first = data.subdata(in: 0..<8)

            var offset : UInt32 = first.withUnsafeBytes { $0.pointee }
            
            print(offset)
//        }
        return 0
    }
}
