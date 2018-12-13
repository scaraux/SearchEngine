//
//  Measure.swift
//  SearchEngine
//
//  Created by Oscar Götting on 12/13/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

struct Measure {
    
    var totalQueries: Int
    var totalTime: Double
    var meanResponseTime: Double
    var meanAveragePrecision: Double
    var throughPut: Double
    
    init(totalQueries: Int, totalTime: Double, meanResponseTime: Double, meanAvgPrecision: Double, throughPut: Double) {
        self.totalQueries = totalQueries
        self.totalTime = totalTime
        self.meanResponseTime = meanResponseTime
        self.meanAveragePrecision = meanAvgPrecision
        self.throughPut = throughPut
    }
}
