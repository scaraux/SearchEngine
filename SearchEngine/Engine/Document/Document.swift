//
//  DocumentProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol Document {
    
    var documentId: Int { get }

    var title: String { get }
    
    func getContent() -> StreamReader?
    
    static func getFactory() -> DocumentFactoryProtocol

}
