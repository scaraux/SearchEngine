//
//  DiskConstants.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

public struct DiskConstants {
    static let indexDirectoryName = "index"
    static let postingsDiskFileName = "postings.bin"
    static let weightsDiskFileName = "weights.bin"
    static let vocabularyDiskFileName = "vocab.bin"
    static let typesDiskFileName = "types.bin"
    static let tableDiskFileName = "vocab_table.bin"
    static let gramDiskFileName = "grams.bin"
    
    enum FileDescriptorMode {
        case reading
        case writing
        case updating
    }
}
