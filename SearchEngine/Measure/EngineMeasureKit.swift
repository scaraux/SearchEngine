//
//  EngineMeasureKit.swift
//  SearchEngine
//
//  Created by Oscar Götting on 12/12/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class EngineMeasureKit {
    
    var engine: Engine
    var path: URL
    var queries: [String] = []
    var relevances: [[Int]] = []
    var precisions: [Double] = []
    var responseTimes: [Double] = []
    
    weak var delegate: MeasureKitProtocol?

    init?(url: URL, engine: Engine) {
        self.path = url
        self.engine = engine
        
        let queryFile = url.appendingPathComponent("queries.dat")
        let relevanceFile = url.appendingPathComponent("qrel.dat")
        
        var queryList: [String]
        var relevanceLists: [String]

        do {
            let data = try String(contentsOf: queryFile, encoding: .utf8)
            queryList = data.components(separatedBy: "\r\n")
        } catch {
            print(error)
            return nil
        }
        
        do {
            let data = try String(contentsOf: relevanceFile, encoding: .utf8)
            relevanceLists = data.components(separatedBy: "\r\n")
        } catch {
            print(error)
            return nil
        }
        
        if queryList.count != relevanceLists.count {
            return nil
        }
        
        for queryIndex in 0..<queryList.count {
            let query = queryList[queryIndex]
            let relevanceList = relevanceLists[queryIndex]
            let relevantDocuments: [String] = relevanceList.components(separatedBy: .whitespaces)
            let relevantDocumentIds: [Int] = relevantDocuments.compactMap { Int($0) }
            self.queries.append(query)
            self.relevances.append(relevantDocumentIds)
        }
    }
    
    func start(withMode mode: Engine.SearchMode) {
        let startTime = DispatchTime.now()
        let totalQueries = self.queries.count
        
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<totalQueries {
                let query = self.queries[i]
                let relevantDocumentsForQuery = self.relevances[i]
                let queryStartTime = DispatchTime.now()
                let results: [QueryResult] = self.engine.execQuerySync(queryString: query,
                                                                       mode: mode,
                                                                       maxResults: relevantDocumentsForQuery.count)
                
                let elapsedTime: Double = self.calculateElapsedTime(from: queryStartTime)
                self.responseTimes.append(elapsedTime)
                
                if mode == .ranked {
                    let queryAveragePrecision: Double = self.calculatePrecision(results: results,
                                                                                relevantDocuments: relevantDocumentsForQuery)
                    self.precisions.append(queryAveragePrecision)
                }
                
                DispatchQueue.main.async {
                    self.delegate?.onPrecisionCalculatedForQuery(queryNb: i, totalQueries: self.queries.count)
                }
            }
    
            let totalTime = self.calculateElapsedTime(from: startTime)
            let meanResponseTime = self.average(self.responseTimes)
            let meanAvgPrecision = mode == .ranked ? self.average(self.precisions) : 0.0
            let throughPut = Double(totalQueries) / totalTime
            
            DispatchQueue.main.async {
                let measure = Measure(totalQueries: totalQueries,
                                      totalTime: totalTime,
                                      meanResponseTime: meanResponseTime,
                                      meanAvgPrecision: meanAvgPrecision,
                                      throughPut: throughPut)
                self.delegate?.onMeasurementsReady(measure: measure)
            }
        }
    }
    
    func calculatePrecision(results: [QueryResult], relevantDocuments: [Int]) -> Double {
        
        var cumulatedPrecisionAtK: Double = 0.0
        var relevantDocumentsCount: Double = 0
        
        for i in 0..<results.count {
            let result = results[i]
            let documentNameAsStringId: String = result.document!.fileURL.deletingPathExtension().lastPathComponent
            let documentNameAsId: Int = Int(documentNameAsStringId)!
        
            if relevantDocuments.contains(documentNameAsId) {
                relevantDocumentsCount += 1
                cumulatedPrecisionAtK += relevantDocumentsCount / Double(i + 1)
            }
        }
        
        if relevantDocumentsCount > 0 {
            return cumulatedPrecisionAtK / relevantDocumentsCount
        }
        return 0.0
    }
    
    private func calculateElapsedTime(from: DispatchTime) -> Double {
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - from.uptimeNanoseconds
        return Double(nanoTime) / 1_000_000_000
    }
    
    func average(_ nums: [Double]) -> Double {
        var total = 0.0
        for num in nums {
            total += Double(num)
        }
        return total / Double(nums.count)
    }
}
