import Foundation

internal class ProgressTable {
    private var buffer: [Int]
    
    public init(size: Int) {
        self.buffer = Array(repeating: 0, count: size)
    }
    
    public var size: Int {
        return buffer.count
    }
    
    public subscript(k k: Int) -> Int {
        get {
            return buffer[wrap(k: k)]
        }
        set {
            buffer[wrap(k: k)] = newValue
        }
    }
    
    private func wrap(k: Int) -> Int {
        var k = k
        k %= size
        if k < 0 {
            k += size
        }
        return k
    }
}
