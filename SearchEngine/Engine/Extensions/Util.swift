//
//  Util.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/6/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class Utils {
    
    static func printDiff(start: DispatchTime, message: String = "") {
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000
        print("\(message) \(timeInterval)")
    }
}
