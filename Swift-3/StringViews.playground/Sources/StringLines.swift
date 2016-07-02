import Foundation

extension String {

    public struct LinesView {
        private let source: String
        public let indices: String.CharacterView.Indices

        private init(_ source: String, indices: String.CharacterView.Indices) {
            self.source = source
            self.indices = indices
        }
    }

    public var lines: LinesView {
        return .init(self, indices: characters.indices)
    }

}

extension String.LinesView: BidirectionalCollection, CustomStringConvertible, CustomDebugStringConvertible {

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
        source.getLineStart(&unusedStart, end: &i, contentsEnd: &unusedContentsEnd, for: i ..< i)
    }

    public func index(after i: String.CharacterView.Index) -> String.CharacterView.Index {
        var ret = i
        formIndex(after: &ret)
        return ret
    }

    public func formIndex(before i: inout String.CharacterView.Index) {
        guard i > indices.startIndex else { return }

        var unusedEnd = indices.endIndex
        var unusedContentsEnd = indices.endIndex
        source.characters.formIndex(before: &i)
        source.getLineStart(&i, end: &unusedEnd, contentsEnd: &unusedContentsEnd, for: i ..< i)
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
        source.getLineStart(&start, end: &unusedEndIndex, contentsEnd: &end, for: i ..< i)
        return source[start ..< end]
    }

    public subscript(bounds: Range<String.CharacterView.Index>) -> String.LinesView {
        return .init(source, indices: indices[bounds])
    }

    public var description: String {
        return String(source)
    }

    public var debugDescription: String {
        return String(reflecting: source)
    }
    
}
