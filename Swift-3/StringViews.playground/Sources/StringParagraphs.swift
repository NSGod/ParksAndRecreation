import Foundation

extension String {

    public struct ParagraphsView {
        private let source: String
        public let indices: String.CharacterView.Indices

        private init(_ source: String, indices: String.CharacterView.Indices) {
            self.source = source
            self.indices = indices
        }
    }

    public var paragraphs: ParagraphsView {
        return .init(self, indices: characters.indices)
    }

}

extension String.ParagraphsView: BidirectionalCollection, CustomStringConvertible, CustomDebugStringConvertible {

    public var startIndex: String.CharacterView.Index {
        return indices.startIndex
    }

    public var endIndex: String.CharacterView.Index {
        return indices.endIndex
    }

    public func formIndex(after i: inout String.CharacterView.Index) {
        guard i < indices.endIndex else { return }

        var unusedStart = indices.startIndex
        var unusedContentsEnd = indices.endIndex
        source.getParagraphStart(&unusedStart, end: &i, contentsEnd: &unusedContentsEnd, for: i ..< i)
    }

    public func index(after i: String.CharacterView.Index) -> String.CharacterView.Index {
        var ret = i
        formIndex(after: &ret)
        return ret
    }

    public func formIndex(before i: inout String.CharacterView.Index) {
        guard i > indices.startIndex else { return }

        source.characters.formIndex(before: &i)
        var unusedEnd = indices.endIndex
        var unusedContentsEnd = indices.endIndex
        source.getParagraphStart(&i, end: &unusedEnd, contentsEnd: &unusedContentsEnd, for: i ..< i)
    }

    public func index(before i: String.CharacterView.Index) -> String.CharacterView.Index {
        var ret = i
        formIndex(before: &ret)
        return ret
    }

    public subscript(i: String.CharacterView.Index) -> String {
        guard i != indices.endIndex else { return "" }
        var start = indices.startIndex
        var unusedEndIndex = indices.endIndex
        var end = indices.endIndex
        source.getParagraphStart(&start, end: &unusedEndIndex, contentsEnd: &end, for: i ..< i)
        return source[start ..< end]
    }

    public subscript(bounds: Range<String.CharacterView.Index>) -> String.ParagraphsView {
        return .init(source, indices: indices[bounds])
    }

    public var description: String {
        return String(source)
    }

    public var debugDescription: String {
        return String(reflecting: source)
    }

}

/*extension String.ParagraphIndex: Comparable {

    public func predecessor() -> String.ParagraphIndex {
        guard location != source.startIndex else { return self }

        var next = location.predecessor()
        source.getParagraphStart(&next, end: nil, contentsEnd: nil, for: next ..< next)
        return .init(source, location: next)
    }

    public func successor() -> String.ParagraphIndex {
        guard location != source.endIndex else { return self }

        var next = location
        source.getParagraphStart(nil, end: &next, contentsEnd: nil, for: next ..< next)
        return .init(source, location: next)
    }

}

public func == (lhs: String.ParagraphIndex, rhs: String.ParagraphIndex) -> Bool {
    return lhs.location == rhs.location
}
*/
