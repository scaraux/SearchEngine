//
//  KGramIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/28/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class GramIndex: GramIndexProtocol {
    
    struct Constants {
        static let MaximumGramLength = 3
        static let DollarSignCharacter = "$"
        static let WildcardCharacter = "*"
    }
    
    var map: [String: Set<VocabularyElement>]
    
    init() {
        self.map = [String: Set<VocabularyElement>]()
    }
    
    init(withMap map: [String: Set<VocabularyElement>]) {
        self.map = map
    }
    
    private func withTypes<R>(forGram gram: String,
                              mutations: (inout Set<VocabularyElement>) throws -> R) rethrows -> R {
        return try mutations(&map[gram, default: []])
    }
    
    func getSimilarCandidatesFor(term: String) -> [VocabularyElement]? {
        var candidates = [VocabularyElement]()
        let grams = getMatchingGramsForNonWildCard(term: term)!
        
        if let newCandidates = self.map[grams[0]] {
            candidates = Array(newCandidates)
        }
        for i in 1 ..< grams.count {
            if let newCandidates = self.map[grams[i]] {
                candidates = Array(Set(candidates).union(Set(newCandidates)))
            }
        }
        return candidates.isEmpty ? nil : candidates
    }
    
    func getMatchingCandidatesFor(term: String) -> [VocabularyElement]? {
        var candidates = [VocabularyElement]()
        let grams = getMatchingGramsFor(term: term)!
        
        if let newCandidates = self.map[grams[0]] {
            candidates = Array(newCandidates)
        }
        else {
            return nil
        }
        for i in 1 ..< grams.count {
            if let newCandidates = self.map[grams[i]] {
                candidates = Array(Set(candidates).intersection(Set(newCandidates)))
            }
            else {
                return nil
            }
        }
        return candidates.isEmpty ? nil : candidates
    }
    
    private func addElementCandidateForGram(gram: String, element: VocabularyElement) {
        _ = withTypes(forGram: gram) { types in
            types.insert(element)
        }
    }

    func registerGramsFor(vocabularyElement element: VocabularyElement) {
        // Initialize i to 0
        var i: Int = 0
        // Wrap the term with dollar signs, at beginning and end
        let dollarWrappedType = Constants.DollarSignCharacter + element.type + Constants.DollarSignCharacter
        // Iterate on type characters
        while i < dollarWrappedType.count {
            // Calculate the maximum length to start with, for the grams that will be generated from the type
            // If type length exceeds the maximum gram length we handle in the index, then we will use
            // this maximum length as reference.
            // Otherwise, the maximum gram size for this type will be based on its length
            var gramSize = dollarWrappedType.count > Constants.MaximumGramLength ?
                Constants.MaximumGramLength : dollarWrappedType.count
            // Iterate on possible gram sizes
            while gramSize > 0 {
                var gram: String
                // Generate gram of size gramSize for the type
                if i + gramSize <= dollarWrappedType.count {
                    gram = String(dollarWrappedType[i..<(i + gramSize)])
                    if gram != Constants.DollarSignCharacter {
                        addElementCandidateForGram(gram: gram, element: element)
                    }
                }
                gramSize -= 1
            }
            i += 1
        }
    }
    
    private func getMatchingGramsForNonWildCard(term: String) -> [String]? {
        var grams = [String]()
        // Wrap the term with dollar signs, at beginning and end
        let term = Constants.DollarSignCharacter + term + Constants.DollarSignCharacter
        var i: Int = 0
        // Iterate on subterm characters
        while i < term.count {
            var gram: String
            // Calculate the maximum length for each of the grams we will build from the term
            // If term length exceeds the maximum gram length we handle in the index, then we will use
            // this maximum length as reference. Otherwise, the grams will be based on the term length
            let maximumGramLengthForTerm = term.count >= Constants.MaximumGramLength ?
                Constants.MaximumGramLength : term.count
            // If we can't find anymore grams of maximum length from i, jump to next subterm
            if i + maximumGramLengthForTerm > term.count {
                break
            }
            // If gram is more than 1 character long, we build a substring
            if maximumGramLengthForTerm > 1 {
                gram = String(term[i..<(i + maximumGramLengthForTerm)])
            }
                // If gram is only one character long, the gram is the character itself
            else {
                gram = String(term[i])
            }
            // Append gram to the list of grams to be returned
            grams.append(gram)
            i += 1
        }
        return grams
    }
    
    private func getMatchingGramsFor(term: String) -> [String]? {
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
            while i < subTerm.count {
                var gram: String
                // Calculate the maximum length for each of the grams we will build from the term
                // If term length exceeds the maximum gram length we handle in the index, then we will use
                // this maximum length as reference. Otherwise, the grams will be based on the term length
                let maximumGramLengthForTerm = subTerm.count >= Constants.MaximumGramLength ?
                    Constants.MaximumGramLength : subTerm.count
                // If we can't find anymore grams of maximum length from i, jump to next subterm
                if i + maximumGramLengthForTerm > subTerm.count {
                    break
                }
                // If gram is more than 1 character long, we build a substring
                if maximumGramLengthForTerm > 1 {
                    gram = String(subTerm[i..<(i + maximumGramLengthForTerm)])
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
