//
//  TruncatingLabel.swift
//
//  Created by Zachary Waldowski on 6/27/15.
//  Copyright (c) 2015 Zachary Waldowski. Some rights reserved. Licensed under MIT.
//

import UIKit

private extension NSMutableAttributedString {
    
    func updateAttributeInPlace<T: AnyObject>(_ name: String, ofType _: T.Type = T.self, options: EnumerationOptions = [], transform: (T) -> T?) {
        enumerateAttribute(name, in: .init(0 ..< string.utf16.count), options: options) { (obj, range, _) in
            if let newValue = transform(obj as! T) {
                addAttribute(name, value: newValue, range: range)
            } else {
                removeAttribute(name, range: range)
            }
        }
    }
    
    func deleteAllCharacters() {
        deleteCharacters(in: .init(0 ..< string.utf16.count))
    }
    
}

private extension NSLayoutManager {
    
    func textContainer(glyphIndex index: Int) -> (NSTextContainer, effectiveRange: NSRange)? {
        var range = NSRange(location: NSNotFound, length: 0)
        if let textContainer = self.textContainer(forGlyphAt: index, effectiveRange: &range) {
            return (textContainer, range)
        } else {
            return nil
        }
    }
    
    func invalidateGlyphs(for range: Range<String.Index>, changeInLength delta: String.IndexDistance = 0) {
        let string = textStorage?.string ?? ""
        let range = NSRange(range, within: string)
        invalidateGlyphs(forCharacterRange: range, changeInLength: delta, actualCharacterRange: nil)
    }
    
    func truncationInfo(forGlyphsIn glyphRange: NSRange) -> (NSRange, lineIndex: Int, glyphOffset: Int)? {
        var truncatedLineIndex = 0
        var truncatedLineGlyph = 0
        var truncatedGlyphs: NSRange?
        
        enumerateLineFragments(forGlyphRange: glyphRange) { [unowned self] (_, _, _, range, stop) in
            let thisLineTruncated = self.truncatedGlyphRange(inLineFragmentForGlyphAt: range.location)
            if thisLineTruncated.location != NSNotFound {
                truncatedGlyphs = thisLineTruncated
                truncatedLineGlyph = range.location
                stop.pointee = true
            } else {
                truncatedLineIndex += 1
            }
        }
        
        return truncatedGlyphs.map { ($0, truncatedLineIndex, truncatedLineGlyph) }
    }
    
}

private extension NSGlyphProperty {
    
    static var regular: NSGlyphProperty {
        return unsafeBitCast(0, to: NSGlyphProperty.self)
    }
    
}

@IBDesignable
public class TruncatingLabel: UILabel, NSLayoutManagerDelegate {
    
    // MARK: - Lifecycle
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        updateTextStore()
    }

    // MARK: - Text Storage
    
    private lazy var textStorage = NSTextStorage()
    
    private lazy var textContainer: NSTextContainer = {
        let textContainer = NSTextContainer()
        textContainer.maximumNumberOfLines = self.numberOfLines
        textContainer.lineBreakMode = self.lineBreakMode
        textContainer.lineFragmentPadding = 0
        return textContainer
    }()
    
    private lazy var layoutManager: NSLayoutManager = {
        let layoutManager = NSLayoutManager()
        layoutManager.delegate = self
        layoutManager.addTextContainer(self.textContainer)
        self.textStorage.addLayoutManager(layoutManager)
        return layoutManager
    }()
    
    private lazy var truncationDrawingContext = NSStringDrawingContext()
    
    // MARK: - Properties
    
    private var truncationTextStorage: String?
    
    /** Text to display when truncated, displayed at the trailing end of multi-line
    * text. The default is "more". The @c truncationText is displayed in the
    * @c tintColor of this view.
    **/
    public var truncationText: String! {
        get {
            return truncationTextStorage ?? NSLocalizedString("more", comment: "Default text to display after truncated text")
        }
        set {
            truncationTextStorage = newValue
            invalidateCustomTruncation()
            setNeedsDisplay()
        }
    }
    
    // MARK: - UILabel
    
    public override var numberOfLines: Int {
        willSet {
            textContainer.maximumNumberOfLines = newValue
        }
    }
    
    public override var lineBreakMode: NSLineBreakMode {
        willSet {
            textContainer.lineBreakMode = newValue
        }
    }
    
    public override var text: String? {
        didSet {
            updateTextStore()
        }
    }
    
    public override var attributedText: AttributedString? {
        didSet {
            updateTextStore()
        }
    }
    
    public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        invalidateCustomTruncation()
        textContainer.maximumNumberOfLines = numberOfLines

        switch (bounds.width, bounds.height) {
        case (CGFloat(FLT_MAX), CGFloat(FLT_MAX)):
            textContainer.size = CGRect.infinite.size
        case (let width, CGFloat(FLT_MAX)):
            textContainer.size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        case (CGFloat(FLT_MAX), let height):
            textContainer.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        case let (width, height):
            textContainer.size = CGSize(width: width, height: height)
        }
        forceLayout()
        
        let textBounds = layoutManager.usedRect(for: textContainer)
        let scale = window?.screen.scale ?? 1

        return textBounds.integralizeOutward(scale)
    }
    
    public override func drawText(in rect: CGRect) {
        // force layout, bail for empty layouts
        guard case let (self.textContainer, glyphRange)? = layoutManager.textContainer(glyphIndex: 0) where glyphRange.length != 0 else {
            return
        }
        
        defer {
            layoutManager.drawBackground(forGlyphRange: glyphRange, at: rect.origin)
            layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: rect.origin)
        }
        
        guard !truncationText.isEmpty else { return }
        
        let tokenDrawingOpts = [.usesLineFragmentOrigin, .usesFontLeading] as NSStringDrawingOptions
        let nsTruncationText = truncationText as NSString
        
        defer {
            switch truncationTextCache {
            case .none, .needsUpdate:
                break
            case .cached(var truncationFrame, let attributes):
                truncationFrame.origin.x += rect.minX
                truncationFrame.origin.y += rect.minY
                nsTruncationText.draw(with: truncationFrame, options: tokenDrawingOpts, attributes: attributes, context: truncationTextContext)
            }
        }
        
        guard case .needsUpdate = truncationTextCache else {
            return
        }
        
        guard let (truncatedGlyphs, truncatedLineIndex, truncatedLineGlyph) = layoutManager.truncationInfo(forGlyphsIn: glyphRange), truncatedCharsUTF16 = layoutManager.characterRange(forGlyphRange: truncatedGlyphs, actualGlyphRange: nil).toRange() where truncatedLineIndex > 0 else {
            truncationTextCache = .none
            return
        }
        
        let string = textStorage.string
        let minIndex = string.startIndex
        var moreAttributes = textStorage.attributes(at: truncatedCharsUTF16.lowerBound, effectiveRange: nil) 
        var moreBounding = nsTruncationText.boundingRect(with: CGSize.zero, options: tokenDrawingOpts, attributes: moreAttributes, context: truncationTextContext)
        
        var newTruncation = string.utf16.index(string.utf16.startIndex, offsetBy: truncatedCharsUTF16.lowerBound).samePosition(in: string) ?? minIndex
        var truncatedLineRect: CGRect
        repeat {
            guard newTruncation != minIndex else {
                customTruncationStart = nil
                truncationTextCache = .none
                return
            }

            string.characters.formIndex(before: &newTruncation)
            customTruncationStart = newTruncation
            layoutManager.invalidateGlyphs(for: newTruncation..<string.endIndex)
            
            truncatedLineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: truncatedLineGlyph, effectiveRange: nil)
        } while rect.width - truncatedLineRect.width < moreBounding.width
        
        if truncatedLineRect.minX > rect.minX { // RTL
            moreBounding.origin.x = rect.minX
        } else {
            moreBounding.origin.x = rect.maxX - moreBounding.width
        }
        moreBounding.origin.y += truncatedLineRect.minY
        moreAttributes[NSForegroundColorAttributeName] = tintColor
        
        truncationTextCache = .cached(moreBounding, moreAttributes)
    }
    
    // MARK: - UIView
    
    public override func tintColorDidChange() {
        super.tintColorDidChange()
        
        switch truncationTextCache {
        case .none:
            break
        case .needsUpdate:
            setNeedsDisplay()
        case .cached(let rect, var attributes):
            attributes[NSForegroundColorAttributeName] = tintColor
            truncationTextCache = .cached(rect, attributes)
            setNeedsDisplay()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let newSize = bounds.size
        if textContainer.size != newSize {
            invalidateCustomTruncation()
            textContainer.size = newSize
        }
    }
    
    // MARK: - UI
    
    private var lastNumberOfLines = 0
    
    @IBAction public func toggleTruncation() {
        swap(&numberOfLines, &lastNumberOfLines)
    }
    
    // MARK: - Text Truncation
    
    private enum TruncationInfo {
        case none
        case needsUpdate
        case cached(CGRect, [String: AnyObject])
    }
    
    private var customTruncationStart: String.Index?
    private var truncationTextCache = TruncationInfo.needsUpdate
    private lazy var truncationTextContext = NSStringDrawingContext()
    
    // MARK: - Internal
    
    private func updateTextStore() {
        textStorage.beginEditing()
        defer {
            textStorage.endEditing()
        }
        
        guard let attributedString = attributedText else {
            textStorage.deleteAllCharacters()
            return
        }
        
        textStorage.setAttributedString(attributedString)
        textStorage.updateAttributeInPlace(NSParagraphStyleAttributeName, ofType: NSParagraphStyle.self) {
            let mutablePStyle = $0.mutableCopy() as! NSMutableParagraphStyle
            mutablePStyle.lineBreakMode = .byWordWrapping
            return mutablePStyle
        }
    }
    
    private func invalidateCustomTruncation() {
        if let start = customTruncationStart {
            customTruncationStart = nil
            layoutManager.invalidateGlyphs(for: start ..< textStorage.string.endIndex)
        }
        truncationTextCache = .needsUpdate
    }
    
    private func forceLayout() {
        layoutManager.ensureLayout(forCharacterRange: .init(0 ..< textStorage.string.utf16.count))
    }
    
    // MARK: - NSLayoutManagerDelegate

    private func extendToIncludeTrailingWhitespace(at index: inout String.Index, within string: String) {
        guard index != string.endIndex, let whiteSpaceRange = string.rangeOfCharacter(from: .whitespaces, options: .backwardsSearch, range: string.startIndex ..< string.index(after: index)) where whiteSpaceRange.upperBound == index else { return }
        index = whiteSpaceRange.lowerBound
    }
    
    public func layoutManager(_ layoutManager: NSLayoutManager, shouldGenerateGlyphs glyphsPtr: UnsafePointer<CGGlyph>, properties propertiesPtr: UnsafePointer<NSGlyphProperty>, characterIndexes charIndexesUTF16Ptr: UnsafePointer<Int>, font: UIFont, forGlyphRange inGlyphRange: NSRange) -> Int {
        guard var truncationChar = customTruncationStart, let glyphRange = inGlyphRange.toRange(), string = layoutManager.textStorage?.string else {
            return 0
        }
        
        let glyphsCount = glyphRange.count
        let charIndexesUTF16 = UnsafeBufferPointer(start: charIndexesUTF16Ptr, count: glyphsCount)
        let charIndexes = charIndexesUTF16.lazy.map {
            string.utf16.index(string.utf16.startIndex, offsetBy: $0).samePosition(in: string)!
        }
        
        // Bail if we don't need to truncated
        let characterRange = charIndexes[charIndexes.startIndex]...charIndexes[(charIndexes.endIndex - 1)]
        guard characterRange.contains(truncationChar) else {
            return 0
        }

        // Include trailing whitespace while truncating
        extendToIncludeTrailingWhitespace(at: &truncationChar, within: string)
        guard let glyphOffset = charIndexes.index(of: truncationChar) else {
            return 0
        }

        
        // Flush the pre-generated glyphs up to this point
        if truncationChar != string.startIndex {
            layoutManager.setGlyphs(glyphsPtr, properties: propertiesPtr, characterIndexes: charIndexesUTF16Ptr, font: font, forGlyphRange: NSRange(location: glyphRange.lowerBound, length: glyphOffset))
        }

        // Substitute "..." as the glyph for the truncation
        var ellipsis: UniChar = 0x2026
        var truncationGlyph = kCGFontIndexInvalid
        var truncationIndex = charIndexesUTF16[glyphOffset]
        var truncationProperty: NSGlyphProperty = CTFontGetGlyphsForCharacters(font, &ellipsis, &truncationGlyph, 1) ? .regular : .controlCharacter

        layoutManager.setGlyphs(&truncationGlyph, properties: &truncationProperty, characterIndexes: &truncationIndex, font: font, forGlyphRange: NSRange(location: glyphRange.lowerBound + glyphOffset, length: 1))

        // Ignore remaining glyphs. Offset charIndexesUTF16Ptr by 1, but glyphRange by 2
        let glyphSkipped = (glyphOffset + 1)
        if glyphsCount > glyphSkipped {
            var truncationProperties = [NSGlyphProperty](repeating: .null, count: 32)
            for glyphOffset in stride(from: glyphSkipped, to: glyphsCount, by: truncationProperties.count) {
                let start = glyphRange.lowerBound + glyphOffset
                let end = min(start + truncationProperties.count, glyphRange.upperBound)
                layoutManager.setGlyphs(glyphsPtr + glyphOffset, properties: &truncationProperties, characterIndexes: charIndexesUTF16Ptr + glyphOffset, font: font, forGlyphRange: .init(start ..< end))
            }
        }
        
        return glyphsCount
    }

}
