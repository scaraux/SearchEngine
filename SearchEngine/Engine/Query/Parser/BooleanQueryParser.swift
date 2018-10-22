//
//  BooleanQueryParser.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/16/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class BooleanQueryParser {
    
    struct Constants {
        static let DoubleQuoteCharacter = Character("\"")
        static let WildCardCharacter = Character("*")
        static let SpaceCharacter = Character(" ")
        static let PlusCharacter = Character("+")
    }
    
    struct StringBounds {
        
        var start: Int
        var length: Int
        
        init(start: Int, length: Int) {
            self.start = start
            self.length = length
        }
    }
    
    class Literal {
        
        let stringBounds: StringBounds
        let literalComponent: Queriable
        
        init(bounds: StringBounds, literal: Queriable) {
            self.stringBounds = bounds
            self.literalComponent = literal
        }
    }
    
    func parseQuery(query: String) -> Queriable? {
        
        var start: Int = 0
        var allSubqueries = [Queriable]()
        // General routine: scan the query to identify a literal, and put that literal into a list.
        // Repeat until a + or the end of the query is encountered; build an AND query with each
        // of the literals found. Repeat the scan-and-build-AND-query phase for each segment of the
        // query separated by + signs. In the end, build a single OR query that composes all of the built
        // AND subqueries.
        repeat {
            // Identify the next subquery: a portion of the query up to the next + sign.
            let nextSubquery: StringBounds = findNextSubquery(query, startIndex: start)
            // Extract the identified subquery into its own string.
            let subQuery: String? = query.substring(nextSubquery.start, nextSubquery.length)
            
            var subStart: Int = 0
            // Substring failed, fatalError
            if subQuery == nil {
                fatalError("Cannot parse message")
            }
            // Store all the individual components of this subquery.
            var subqueryLiterals = [Queriable]()
            
            repeat {
                // Extract the next literal from the subquery.
                let lit: Literal = findNextLiteral(subquery: subQuery!, startIndex: subStart)
                // Add the literal component to the conjunctive list.
                subqueryLiterals.append(lit.literalComponent)
                // Set the next index to start searching for a literal.
                subStart = lit.stringBounds.start + lit.stringBounds.length
            } while subStart < subQuery!.count
            
            // After processing all literals, we are left with a list of query components that we are
            // ANDing together, and must fold that list into the final OR list of components.
            // If there was only one literal in the subquery, we don't need to AND it with anything --
            // its component can go straight into the list.
            if subqueryLiterals.count == 1 {
                allSubqueries.append(subqueryLiterals[0])
            }
            // With more than one literal, we must wrap them in an AndQuery component.
            else {
                allSubqueries.append(AndQuery(components: subqueryLiterals))
            }
            start = nextSubquery.start + nextSubquery.length
            
        } while start < query.count
        // After processing all subqueries, we either have a single component or multiple components
        // that must be combined with an OrQuery.
        if allSubqueries.count == 1 {
            return allSubqueries[0]
        }
        else if allSubqueries.count > 1 {
            return OrQuery(components: allSubqueries)
        }
        else {
            return nil
        }
    }
    
    private func findNextSubquery(_ query: String, startIndex: Int) -> StringBounds {
        var lengthOut: Int
        var startPosition = startIndex
        
        // Find the start of the next subquery by skipping spaces and + signs.
        while query[startPosition] == Constants.SpaceCharacter || query[startPosition] == Constants.PlusCharacter {
            startPosition += 1
        }
        // Find the end of the next subquery.
        var nextPlus: Int = query.nextIndexAfter(character: Constants.PlusCharacter, from: startPosition + 1)
        // If there is no other + sign, then this is the final subquery in the
        // query string.
        if nextPlus < 0 {
            lengthOut = query.count - startPosition
        }
        // If there is another + sign, then the length of this subquery goes up
        // to the next + sign.
        else {
            // Move nextPlus backwards until finding a non-space non-plus character.
            while query[nextPlus] == Constants.SpaceCharacter || query[nextPlus] == Constants.PlusCharacter {
                nextPlus -= 1
            }
            lengthOut = 1 + nextPlus - startPosition
        }
        return StringBounds(start: startPosition, length: lengthOut)
    }
    
    private func findNextLiteral(subquery: String, startIndex: Int) -> Literal {
        let nextDelimiter: Int
        let subLength: Int = subquery.count
        var isPhrase: Bool = false
        var startIndex = startIndex
        var lengthOut: Int
        
        // Skip past white spaces
        while subquery[startIndex] == Constants.SpaceCharacter {
            startIndex += 1
        }
        // If subquery starts by a " character, its a phrase literal
        // Locate the next closing " to find the end of this phrase
        if subquery[startIndex] == Constants.DoubleQuoteCharacter {
            isPhrase = true
            nextDelimiter = subquery.nextIndexAfter(character: Constants.DoubleQuoteCharacter, from: startIndex + 1) + 1
        }
        // Locate the next space to find the end of this literal.
        else {
            nextDelimiter = subquery.nextIndexAfter(character: Constants.SpaceCharacter, from: startIndex)
        }
        // No more literals in this subquery.
        if nextDelimiter < 0 {
            // No end delimiter for phrase literal
            if isPhrase {
                fatalError("Cannot parse query, phrase literal needs to end with a \"")
            }
            lengthOut = subLength - startIndex
        }
        else {
            lengthOut = nextDelimiter - startIndex
        }
        // Final bounds for term
        let finalBounds = StringBounds(start: startIndex, length: lengthOut)
        // String representation of the term
        guard let term = subquery.substring(startIndex, lengthOut) else {
            fatalError("Cannot find next literal for string \(subquery) at position \(startIndex)")
        }
        // If term contains * its a WildcardLiteral
        if term.contains(Constants.WildCardCharacter) {
            return Literal(bounds: finalBounds, literal: WildcardLiteral(term: term))
        }
        // If term is a phrase, add it as PhraseLiteral
        if isPhrase {
            let phraseTerms = term.replacingOccurrences(of: "\"",
                                                        with: "",
                                                        options: NSString.CompareOptions.literal, range: nil)
            return Literal(bounds: finalBounds, literal: PhraseLiteral(terms: phraseTerms))
        }
        // Term is regular, add as TermLiteral
        return Literal(bounds: finalBounds, literal: TermLiteral(term: term))
    }
}
