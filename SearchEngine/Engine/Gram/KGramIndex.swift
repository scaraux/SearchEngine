//
//  KGramIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/28/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class KGramIndex {
    
    struct Constants {
        static let MaximumGramLength = 3
        static let DollarSignCharacter = "$"
        static let WildcardCharacter = "*"
    }
    
    var gramIndex: [String:[String]]
    
    private static var privateShared: KGramIndex?
    
    private init() {
        self.gramIndex = [String:[String]]()
    }
    
    class func shared() -> KGramIndex { // change class to final to prevent override
        guard let pShared = privateShared else {
            privateShared = KGramIndex()
            return privateShared!
        }
        return pShared
    }
    
    class func destroy() -> Void {
        privateShared = nil
    }
    
    private func addTypeCandidateForGram(gram: String, type: String) -> Void {
        if self.gramIndex[gram] == nil {
            self.gramIndex[gram] = [String]()
        }
        self.gramIndex[gram]!.append(type)
    }
    
    func test() {
        print("test")
    }

    func getMatchingCandidatesFor(gram: String) -> [String]? {
        return self.gramIndex[gram]
    }
    
    
    func registerGramsFor(type: String) -> Void {
        var i: Int = 0
        // Wrap the term with dollar signs, at beginning and end
        let dollarWrappedType = Constants.DollarSignCharacter + type + Constants.DollarSignCharacter
        // Iterate on type characters
        while (i < dollarWrappedType.count) {
            // Calculate the maximum length to start with, for the grams that will be generated from the type
            // If type length exceeds the maximum gram length we handle in the index, then we will use
            // this maximum length as reference.
            // Otherwise, the maximum gram size for this type will be based on its length
            var gramSize = dollarWrappedType.count > Constants.MaximumGramLength ? Constants.MaximumGramLength : dollarWrappedType.count
            // Iterate on possible gram sizes
            while gramSize > 0 {
                var gram: String
                // Generate gram of size gramSize for the type
                if i + gramSize <= dollarWrappedType.count {
                    gram = String(dollarWrappedType[i..<(i + gramSize)])
                    if gram != Constants.DollarSignCharacter {
                        addTypeCandidateForGram(gram: gram, type: type)
                    }
                }
                gramSize -= 1
            }
            i += 1
        }
    }
    
    func getMatchingGramsFor(term: String) -> [String]? {
        var grams = [String]()
        // Wrap the term with dollar signs, at beginning and end
        let term = Constants.DollarSignCharacter + term + Constants.DollarSignCharacter
        // Split the term by wildcard occurences
        let subTerms = term.components(separatedBy: Constants.WildcardCharacter)
        // Iterate in all subterms
        for subTerm in subTerms {
            // If subcandidate starts or finishes with a * character,
            // then we skip the first or last part of this word
            if subTerm == Constants.DollarSignCharacter {
                continue
            }
            var i: Int = 0
            // Iterate on subterm characters
            while (i < subTerm.count) {
                var gram: String
                // Calculate the maximum length for each of the grams we will build from the term
                // If term length exceeds the maximum gram length we handle in the index, then we will use
                // this maximum length as reference. Otherwise, the grams will be based on the term length
                let maximumGramLengthForTerm = subTerm.count >= Constants.MaximumGramLength ? Constants.MaximumGramLength : subTerm.count
                // If we can't find anymore grams of maximum length from i, jump to next subterm
                if i + maximumGramLengthForTerm > subTerm.count {
                    break
                }
                // If gram is more than 1 character long, we build a substring
                if maximumGramLengthForTerm > 1 {
                    gram = String(subTerm[i..<(i + Constants.MaximumGramLength)])
                }
                // If gram is only one character long, the gram is the character itself
                else {
                    gram = String(subTerm[i])
                }
                // Append gram to the list of grams to be returned
                grams.append(gram)
                i += 1
            }
        }
        return grams
    }
}
