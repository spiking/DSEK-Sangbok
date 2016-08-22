//
//  Extension.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-08-21.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation

// Decode JSON

extension String {
    
    init(htmlEncodedString: String) {
        
        if let encodedData = htmlEncodedString.dataUsingEncoding(NSUTF8StringEncoding){
            
            let attributedOptions : [String: AnyObject] = [
                NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
            ]
            
            do {
                if let attributedString:NSAttributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil){
                    self.init(attributedString.string)
                } else {
                    print("Error")
                    self.init(htmlEncodedString)
                }
                
            } catch {
                print("Error: \(error)")
                self.init(htmlEncodedString)
            }
            
        } else {
            self.init(htmlEncodedString)
        }
    }
}
