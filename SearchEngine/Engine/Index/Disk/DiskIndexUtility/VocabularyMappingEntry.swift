//
//  VocabularyMappingEntry.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/11/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

struct VocabularyMappingEntry {
    
    public let offset: UInt64
    let dataLength: Int
    
    init(atOffset offset: UInt64, ofLength length: Int) {
        self.offset = offset
        self.dataLength = length
    }
}
