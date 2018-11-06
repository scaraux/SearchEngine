//
//  Data+Array.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/21/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

extension Data {
    
    init<T>(fromArray values: [T]) {
        var values = values
        self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
    }
    
    func toArray<T>(type: T.Type) -> [T] {
        return self.withUnsafeBytes {
            [T](UnsafeBufferPointer(start: $0, count: self.count/MemoryLayout<T>.stride))
        }
    }
}
