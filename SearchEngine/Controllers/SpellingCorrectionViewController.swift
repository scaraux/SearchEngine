//
//  SpellingCorrectionViewController.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/13/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Cocoa

protocol SpellingCorrectionDelegate: class {
    func onRequestApplySuggestion(suggestion: SpellingSuggestion)
}

class SpellingCorrectionViewController: NSViewController, NSPopoverDelegate {

    @IBOutlet weak var correctionText: NSTextFieldCell!
    
    var currentCorrection: SpellingSuggestion?
    var corrections: [SpellingSuggestion]?
    weak var delegate: SpellingCorrectionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        previewNextCorrection()
    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return false
    }
    
    private func previewNextCorrection() {
        if self.corrections == nil {
            return
        }
        
        if self.corrections!.count > 0 {
            let correction: SpellingSuggestion = self.corrections!.first!
            self.corrections!.remove(at: 0)
            self.currentCorrection = correction
            self.correctionText.stringValue = "\(correction.mispelledTerm), did you mean \(correction.suggestedTerm) ?"
            return
        }
        self.dismiss(self)
    }
    
    @IBAction func applyTUI(_ sender: Any) {
        delegate?.onRequestApplySuggestion(suggestion: self.currentCorrection!)
        previewNextCorrection()
    }
    
    @IBAction func rejectTUI(_ sender: Any) {
        previewNextCorrection()
    }
    
    @IBAction func discardTUI(_ sender: Any) {
        self.dismiss(nil)
    }
}
