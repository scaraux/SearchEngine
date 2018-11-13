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
    public var weightsFile: BinaryFile
    // The Binary File that holds all the postings
    public var postingsFile: BinaryFile
    // The Binary File that holds all the terms aka vocabulary
    public var vocabularyFile: BinaryFile
    // The Binary File that associate offsets of term - postings
    public var tableFile: BinaryFile
    // The Binary File that holds Gram Index values
    public var typesFile: BinaryFile
    // The Binary File that holds types
    public var gramFile: BinaryFile
    // The URL of the index directory
    public var url: URL
        
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
        // Construct Gram file URL
        let gramFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.gramDiskFileName)
        // Construct Types file URL
        let typesFileURL = url.appendingPathComponent(DiskConstants.indexDirectoryName, isDirectory: true)
            .appendingPathComponent(DiskConstants.typesDiskFileName)
        
        if mode == .writing {
            self.weightsFile = try BinaryFile.createBinaryFile(atPath: weightsFileURL, for: mode)
            self.postingsFile = try BinaryFile.createBinaryFile(atPath: postingsFileURL, for: mode)
            self.vocabularyFile = try BinaryFile.createBinaryFile(atPath: vocabularyFileURL, for: mode)
            self.tableFile = try BinaryFile.createBinaryFile(atPath: tableFileURL, for: mode)
            self.gramFile = try BinaryFile.createBinaryFile(atPath: gramFileURL, for: mode)
            self.typesFile = try BinaryFile.createBinaryFile(atPath: typesFileURL, for: mode)

        } else {
            self.weightsFile = try BinaryFile(atPath: weightsFileURL, for: mode)
            self.postingsFile = try BinaryFile(atPath: postingsFileURL, for: mode)
            self.vocabularyFile = try BinaryFile(atPath: vocabularyFileURL, for: mode)
            self.tableFile = try BinaryFile(atPath: tableFileURL, for: mode)
            self.gramFile = try BinaryFile(atPath: gramFileURL, for: mode)
            self.typesFile = try BinaryFile(atPath: typesFileURL, for: mode)
        }
    }
    
    public func dispose() {
        self.weightsFile.dispose()
        self.postingsFile.dispose()
        self.vocabularyFile.dispose()
        self.tableFile.dispose()
        self.gramFile.dispose()
        self.typesFile.dispose()
    }
}
