//
//  NSRange.swift
//
//  Created by Zachary Waldowski on 7/16/15.
//  Copyright (c) 2015 Big Nerd Ranch. Some rights reserved. Licensed under MIT.
//

import Foundation

public extension NSRange {

    public init(_ utf16Range: Range<String.UTF16View.Index>, within utf16: String.UTF16View) {
        location = utf16.distance(from: utf16.startIndex, to: utf16Range.lowerBound)
        length = utf16.distance(from: utf16Range.lowerBound, to: utf16Range.upperBound)
    }
    
    public init(_ range: Range<String.Index>, within characters: String) {
        let utf16 = characters.utf16
        let utfStart = range.lowerBound.samePosition(in: utf16)
        let utfEnd = range.upperBound.samePosition(in: utf16)
        self.init(utfStart ..< utfEnd, within: utf16)
    }
    
    public func sameRangeIn(_ characters: String) -> Range<String.Index>? {
        guard let range = toRange() else { return nil }

        let utfStart = characters.utf16.index(characters.utf16.startIndex, offsetBy: range.lowerBound)
        let utfEnd = characters.utf16.index(characters.utf16.startIndex, offsetBy: range.upperBound)
        
        guard let start = utfStart.samePosition(in: characters),
            end = utfEnd.samePosition(in: characters) else { return nil }
        
        return start ..< end
    }
    
}
