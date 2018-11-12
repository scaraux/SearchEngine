//
//  VocabularyType.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/11/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

struct VocabularyType: Hashable {
    
    let raw: String
    let stem: String
    
    static func == (lhs: VocabularyType, rhs: VocabularyType) -> Bool {
        return lhs.raw == rhs.raw
    }
    
    init(type: String, stem: String) {
        self.raw = type
        self.stem = stem
    }
}
