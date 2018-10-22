//
//  DiskIndexWriterProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/22/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol DiskIndexWriterProtocol {
    func writeIndex(index: IndexProtocol, atPath url: URL) -> Void
}
