//
//  MeasureKitProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 12/12/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol MeasureKitProtocol: class {
    func onPrecisionCalculatedForQuery(queryNb: Int, totalQueries: Int)
    func onMeasurementsReady(measure: Measure)
}
