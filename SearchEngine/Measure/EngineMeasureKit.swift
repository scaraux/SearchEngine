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
    
    weak var delegate: MeasureKitProtocol?
    
    init?(url: URL, engine: Engine) {
        self.path = url
        self.engine = engine
        
        let queryFile = url.appendingPathComponent("queries_original.dat")
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
        DispatchQueue.global(qos: .userInitiated).async {
            let observation: PreliminaryObservation = self.processQueries(withMode: mode)
            self.analyseResults(withMode: mode, observation: observation)
        }
    }
    
    private func processQueries(withMode mode: Engine.SearchMode) -> PreliminaryObservation {
        var results: [[QueryResult]] = []
        var responseTimes: [Double] = []
        let totalQueries = self.queries.count
        let startTime = DispatchTime.now()
        
        for i in 0..<totalQueries {
            let query = self.queries[i]
            
            let queryStartTime = DispatchTime.now()
            let resultsForQuery: [QueryResult] = self.engine.execQuerySync(queryString: query,
                                                                           mode: mode,
                                                                           maxResults: 50)
            results.append(resultsForQuery)
            
            let elapsedTime: Double = self.calculateElapsedTime(from: queryStartTime)
            responseTimes.append(elapsedTime)
            
            DispatchQueue.main.async {
                self.delegate?.onPrecisionCalculatedForQuery(queryNb: i, totalQueries: self.queries.count)
            }
            
        }
        let totalTime = self.calculateElapsedTime(from: startTime)
        return PreliminaryObservation(results: results, totalTime: totalTime, responseTimes: responseTimes)
    }
    
    private func analyseResults(withMode mode: Engine.SearchMode, observation: PreliminaryObservation) {
        var precisions: [Double] = []
        var accumulators: [Double] = []
        
        for i in 0..<self.queries.count {
            
            let resultsForQuery = observation.results[i]
            let relevantDocumentsForQuery = self.relevances[i]
            
            if mode == .ranked {
                print("------------- \(i) -------------")
                let queryAveragePrecision: Double = self.calculatePrecision(resultsForQuery, relevantDocumentsForQuery)
                print(queryAveragePrecision)
                precisions.append(queryAveragePrecision)
                
                if resultsForQuery.count > 0 {
                    accumulators.append(Double(resultsForQuery.first!.totalAccumulators))
                }
            }
        }
        
        DispatchQueue.main.async {
            let measure = Measure(totalQueries: self.queries.count,
                                  totalTime: observation.totalTime,
                                  meanResponseTime: self.average(observation.responseTimes),
                                  meanAveragePrecision: (mode == .ranked) ? self.average(precisions) : 0.0,
                                  meanAverageAccumulators: (mode == .ranked) ? self.average(accumulators) : 0.0,
                                  throughPut: Double(self.queries.count) / observation.totalTime)
            
            self.delegate?.onMeasurementsReady(measure: measure)
        }
    }
    
    private func calculatePrecision(_ results: [QueryResult], _ relevantDocuments: [Int]) -> Double {
        var cumulatedPrecisionAtK: Double = 0.0
        var relevantDocumentsCount: Double = 0
        
        for i in 0..<results.count {
            let result = results[i]
            let documentNameAsStringId: String = result.document!.fileURL.deletingPathExtension().lastPathComponent
            let documentNameAsId: Int = Int(documentNameAsStringId)!
            
            if relevantDocuments.contains(documentNameAsId) {
                relevantDocumentsCount += 1
                let precisionAtK = relevantDocumentsCount / Double(i + 1)
                print(result.document!.fileName + " relevant , P@K= " + String(precisionAtK))
                cumulatedPrecisionAtK += precisionAtK
            }
            else {
                print(result.document!.fileName + "not relevant")
            }
        }
        
        var res: Double = 0.0
        
        if relevantDocumentsCount > 0 {
            res = cumulatedPrecisionAtK / relevantDocumentsCount
        }
        return res
    }
    
    private func calculateElapsedTime(from: DispatchTime) -> Double {
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - from.uptimeNanoseconds
        return Double(nanoTime) / 1_000_000_000
    }
    
    private func average(_ nums: [Double]) -> Double {
        var total = 0.0
        for num in nums {
            total += Double(num)
        }
        return total / Double(nums.count)
    }
}
