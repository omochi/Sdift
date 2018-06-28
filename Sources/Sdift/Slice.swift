import Foundation

internal class Slice<E> {
    public let elements: [E]
    public let offset: Int
    public let count: Int
    
    public init(elements: [E],
                offset: Int,
                count: Int)
    {
        precondition(0 <= offset)
        precondition(0 <= count)
        precondition(offset + count <= elements.count)
        
        self.elements = elements
        self.offset = offset
        self.count = count
    }

    public subscript(range: Range<Int>) -> Slice<E> {
        get {
            return Slice(elements: elements,
                         offset: offset + range.lowerBound,
                         count: range.count)
        }
    }
}
