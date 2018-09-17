//
//  AndQuery.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/16/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class AndQuery: QueryComponent {
    
    private var components: [QueryComponent]
    
    init(components: [QueryComponent]) {
        self.components = [QueryComponent]()
        self.components.append(contentsOf: components)
    }
    
    func getPostingsFor(index: Index) -> [Posting]? {
        return nil
    }
    
    func toString() -> String {
        return ""
    }
}
