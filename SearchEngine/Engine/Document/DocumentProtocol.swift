//
//  DocumentProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol DocumentProtocol {
    
    var documentId: Int { get }
    var fileName: String { get }
    var title: String { get }
    var weight: Double { get set }
    
    func getContent() -> StreamReader?
    static func getFactory() -> DocumentFactoryProtocol
}
