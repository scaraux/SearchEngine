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
    
    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<self.queries.count {
                let query = self.queries[i]
                let relevantDocumentsForQuery = self.relevances[i]
                
                let results: [QueryResult] = self.engine.execQuerySync(queryString: query,
                                                                       mode: .ranked,
                                                                       maxResults: relevantDocumentsForQuery.count)
                
                let queryAveragePrecision = self.calculatePrecision(results: results,
                                                                    relevantDocuments: relevantDocumentsForQuery)
                
                DispatchQueue.main.async {
                    self.delegate?.onPrecisionCalculatedForQuery(queryNb: i, totalQueries: self.queries.count)
                }
                
                self.precisions.append(queryAveragePrecision)
            }
            
            let meanAveragePrecision = self.average(self.precisions)
            
            DispatchQueue.main.async {
                self.delegate?.onMeasurementsReady(totalQueries: self.queries.count,
                                                   meanAveragePrecision: meanAveragePrecision)
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
    
    func average(_ nums: [Double]) -> Double {
        var total = 0.0
        for num in nums {
            total += Double(num)
        }
        return total / Double(nums.count)
    }
}
