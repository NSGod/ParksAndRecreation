//
//  OrderedDictionary.swift
//  OrderedDictionary
//

public struct OrderedDictionary<Key: Hashable, Value> {

    public typealias Element = Hash.Element

    public typealias Keys = [Key]
    public fileprivate(set) var keys: Keys

    fileprivate typealias Hash = [Key: Value]
    fileprivate var elements: Hash

    fileprivate init(keys: Keys, elements: Hash) {
        self.keys = keys
        self.elements = elements
    }

}

extension OrderedDictionary {

    public init(minimumCapacity: Int) {
        keys = Keys()
        keys.reserveCapacity(minimumCapacity)
        elements = Hash(minimumCapacity: minimumCapacity)
    }

}

extension OrderedDictionary: Collection {

    fileprivate func toItems<T: Collection>(_ keys: T) -> LazyMapCollection<T, Element> where T.Iterator.Element == Key {
        return keys.lazy.map { ($0, self.elements[$0]!) }
    }

    public func makeIterator() -> LazyMapIterator<IndexingIterator<[Key]>, Element> {
        return toItems(keys).makeIterator()
    }

    public var startIndex: Int { return keys.startIndex }
    public var endIndex: Int { return keys.startIndex }

    public subscript (bounds: Range<Int>) -> LazyMapCollection<Keys.SubSequence, Element> {
        return toItems(keys[bounds])
    }

    public var isEmpty: Bool {
        return elements.isEmpty
    }

    public var count: Int {
        return elements.count
    }

}

extension OrderedDictionary: MutableIndexable {

    public subscript(position: Keys.Index) -> Element {
        get {
            guard case keys.indices = position, let value = elements[keys[position]] else {
                preconditionFailure("index out of bounds")
            }
            return (keys[position], value)
        }
        set {
            guard case keys.indices = position , elements.removeValue(forKey: keys[position]) != nil else {
                preconditionFailure("index out of bounds")
            }

            keys[position] = newValue.0
            elements[newValue.0] = newValue.1
        }
    }

}

extension OrderedDictionary {

    public func indexForKey(_ key: Key) -> Int? {
        let hash = key.hashValue
        return keys.index(where: { $0.hashValue == hash })
    }

    public subscript(key: Key) -> Value? {
        get {
            return elements[key]
        }
        set {
            if let newValue = newValue {
                if elements.updateValue(newValue, forKey: key) == nil {
                    keys.append(key)
                }
            } else {
                _ = removeValueForKey(key)
            }
        }
    }

    public mutating func updateElement(_ element: Element, atIndex position: Int) -> Element? {
        guard case keys.indices = position, let oldValue = elements.removeValue(forKey: keys[position]) else {
            preconditionFailure("index out of bounds")
        }

        let oldKey = keys[position]
        keys[position] = element.0
        elements[element.0] = element.1
        return (oldKey, oldValue)
    }

    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let ret = elements.updateValue(value, forKey: key)
        if ret == nil {
            keys.append(key)
        }
        return ret
    }

    public mutating func removeValueForKey(_ key: Key) -> Value? {
        guard let ret = elements.removeValue(forKey: key), let index = indexForKey(key) else { return nil }
        keys.remove(at: index)
        return ret
    }

}

extension OrderedDictionary: RangeReplaceableCollection {

    public init() {
        keys = Keys()
        elements = Hash()
    }

    public mutating func replaceSubrange<C : Collection>(_ subRange: Range<Int>, with newElements: C) where C.Iterator.Element == Element {
        let oldKeys = keys[subRange]

        let newKeys = newElements.lazy.map { $0.0 }
        keys.replaceSubrange(subRange, with: newKeys)

        for oldKey in oldKeys {
            elements.removeValue(forKey: oldKey)
        }

        for (newKey, value) in newElements {
            elements[newKey] = value
        }
    }

    public mutating func insert(_ newElement: Element, at i: Int) {
        var i = i
        if let indexInKeys = indexForKey(newElement.0) {
            keys.remove(at: indexInKeys)
            if i > indexInKeys {
                i += (i - 1)
            }
        }

        keys.insert(newElement.0, at: i)
        elements[newElement.0] = newElement.1
    }

    public mutating func reserveCapacity(_ n: Int) {
        keys.reserveCapacity(n)
    }

    public mutating func remove(at i: Int) -> Element {
        let key = keys.remove(at: i)
        let value = elements.removeValue(forKey: key)
        return (key, value!)
    }

    public mutating func removeFirst() -> Element {
        let key = keys.removeFirst()
        let value = elements.removeValue(forKey: key)
        return (key, value!)
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        keys.removeAll(keepingCapacity: keepCapacity)
        elements.removeAll(keepingCapacity: keepCapacity)
    }

}

extension OrderedDictionary: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral list: Element...) {
        keys = list.map { $0.0 }
        elements = Hash(minimumCapacity: list.count)
        for (key, value) in list {
            elements[key] = value
        }
    }

}

extension OrderedDictionary {

    public var values: LazyMapCollection<Keys, Value> {
        return keys.lazy.map { self.elements[$0]! }
    }

    public mutating func sortInPlace(_ isOrderedBefore: (Element, Element) -> Bool) {
        keys.sort { (key1, key2) -> Bool in
            switch (self.elements.index(forKey: key1), self.elements.index(forKey: key2)) {
            case (.some(let el1), .some(let el2)):
                return isOrderedBefore(self.elements[el1], self.elements[el2])
            case (.none, .some):
                return true
            default:
                return false
            }
        }
    }

    public func sort(_ isOrderedBefore: (Element, Element) -> Bool) -> OrderedDictionary<Key, Value> {
        var new = self
        new.sortInPlace(isOrderedBefore)
        return new
    }

}

extension OrderedDictionary where Key: Comparable {

    public mutating func sortInPlace() {
        sortInPlace { (el1, el2) -> Bool in
            el1.0 < el2.0
        }
    }

    public func sort() -> OrderedDictionary<Key, Value> {
        var new = self
        new.sortInPlace()
        return new
    }

}

extension OrderedDictionary: CustomStringConvertible, CustomDebugStringConvertible {

    fileprivate func makeDescription(debug: Bool) -> String {
        if isEmpty { return "[:]" }

        var result = "["
        var first = true
        for (key, value) in self {
            if first {
                first = false
            } else {
                result += ", "
            }
            if debug {
                debugPrint(key, terminator: "", to: &result)
            } else {
                print(key, terminator: "", to: &result)
            }
            result += ": "
            if debug {
                debugPrint(value, terminator: "", to: &result)
            } else {
                print(value, terminator: "", to: &result)
            }
        }
        result += "]"
        return result
    }

    public var description: String {
        return makeDescription(debug: false)
    }

    public var debugDescription: String {
        return makeDescription(debug: true)
    }
    
}

extension OrderedDictionary: CustomReflectable {
    
    public func customMirror() -> Mirror {
        return Mirror(self, unlabeledChildren: self, displayStyle: .dictionary)
    }
    
}
