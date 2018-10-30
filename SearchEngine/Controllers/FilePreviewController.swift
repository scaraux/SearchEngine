//
//  FilePreviewController.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/30/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Cocoa

class FilePreviewController: NSViewController {

    @IBOutlet var textView: NSTextView!
    
    var fileDocument: FileDocument?
    var queryData: QueryResult?
    
    private struct Constants {
        static let higlightTextAttributes =
            [NSAttributedString.Key.foregroundColor: NSColor.black,
             NSAttributedString.Key.backgroundColor: NSColor.systemPink]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.isEditable = false
        setupText()
    }
    
    func getFileData() -> String? {
        guard let file = self.queryData?.document else {
            return nil
        }
        do {
            return try String(contentsOf: file.fileURL, encoding: String.Encoding.utf8)
        } catch {
            fatalError("Cannot read data from file \(file.fileURL)")
        }
    }
    
    func setupText() {
        guard let query = self.queryData else {
            return
        }
        guard let content = getFileData() else {
            return
        }
        
        let attributes = [NSAttributedString.Key.foregroundColor: NSColor.white]
        let attributedContent = NSMutableAttributedString(string: content, attributes: attributes)
        let area = NSRange(location: 0, length: attributedContent.length)
        let font = NSFont.systemFont(ofSize: 15.0, weight: NSFont.Weight.light)
        
        attributedContent.addAttribute(NSAttributedString.Key.font, value: font, range: area)
        
        for term in query.matchingForTerms {
            let word = " " + term + " "
            var range = NSRange(location: 0, length: attributedContent.length)
            let inputLength = attributedContent.string.count

            while range.location != NSNotFound {
                range = (content as NSString).range(of: word,
                                                    options: [NSString.CompareOptions.caseInsensitive],
                                                    range: range)
                if range.location != NSNotFound {
                    let finalRange = NSRange(location: range.location + 1, length: range.length - 2)
                    attributedContent.addAttributes(Constants.higlightTextAttributes, range: finalRange)
                    range = NSRange(location: range.location + range.length,
                                    length: inputLength - (range.location + range.length))
                }
            }
        }
        self.textView.textStorage?.append(attributedContent)
    }
}
