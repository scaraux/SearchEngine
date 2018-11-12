//
//  VocabularyType.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/11/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

struct VocabularyElement: Hashable {
    
    let type: String
    let stem: String
    
    static func == (lhs: VocabularyElement, rhs: VocabularyElement) -> Bool {
        return lhs.type == rhs.type
    }
    
    init(type: String, stem: String) {
        self.type = type
        self.stem = stem
    }
}
