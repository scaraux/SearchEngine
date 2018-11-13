//
//  String+JaccardIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/12/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

extension String {
    func jaccardCoefficient(other rhs: String) -> Double {
        let lhs = Set(self)
        let rhs = Set(rhs)
        let intersect = Double(lhs.intersection(rhs).count)
        let union = Double(lhs.union(rhs).count)
        return intersect / union
    }
}
