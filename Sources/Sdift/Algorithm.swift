import Foundation

public func difference<C: Collection>
    (old: C, new: C) -> Difference
    where C.Element : Equatable
{
    return difference(old: old,
                      new: new,
                      equals: { $0 == $1 })
}

private struct CacheKey : Hashable {
    var oldIndex: Int
    var newIndex: Int
}

public func difference<OC: Collection, NC: Collection>(
    old: OC,
    new: NC,
    equals: @escaping (OC.Element, NC.Element) -> Bool) -> Difference
{
    return difference(old: Array(old),
                      new: Array(new),
                      equals: equals)
}

public func difference<O, N>(
    old: [O],
    new: [N],
    equals: @escaping (O, N) -> Bool) -> Difference
{
    var solver = Solver(old: old, new: new, equals: equals)
    return solver.difference()
}

internal struct Solver<O, N> {
    private let old: [O]
    private let new: [N]
    private let equalsImpl: (O, N) -> Bool
    
    public init(old: [O],
                new: [N],
                equals equalsImpl: @escaping (O, N) -> Bool)
    {
        self.old = old
        self.new = new
        self.equalsImpl = equalsImpl
    }
    
    private var equalCache: [CacheKey: Bool] = [:]
    
    private mutating func rawEquals(oldIndex: Int, newIndex: Int) -> Bool {
        let cacheKey = CacheKey(oldIndex: oldIndex, newIndex: newIndex)
        if let cache = equalCache[cacheKey] {
            return cache
        }
        
        let oldElement = old[oldIndex]
        let newElement = new[newIndex]
        let result = equalsImpl(oldElement, newElement)
        equalCache[cacheKey] = result
        return result
    }
    
    public mutating func difference() -> Difference {
        let oldSlice = Slice(elements: old,
                             offset: 0,
                             count: old.count)
        let newSlice = Slice(elements: new,
                             offset: 0,
                             count: new.count)
        let diffItems = self.difference(old: oldSlice, new: newSlice)
        return  Difference(diffItems)
    }
    
    private mutating func difference(old: Slice<O>, new: Slice<N>) -> [Difference.Item] {
        func equals(oldIndex: Int, newIndex: Int) -> Bool {
            return rawEquals(oldIndex: old.offset + oldIndex,
                             newIndex: new.offset + newIndex)
        }
        
        if new.count == 0 {
            return (0..<old.count).map { (i) in
                return .remove(oldIndex: old.offset + i)
            }
        }
        
        if old.count == 0 {
            return (0..<new.count).map { (i) in
                return .insert(oldIndex: old.offset,
                               newIndex: new.offset + i)
            }
        }
        
        let maxDistance: Int = old.count + new.count
        let tableSize: Int = 2 * min(old.count, new.count) + 1
        let lengthDiff = old.count - new.count
        
        func reverse(k: Int) -> Int {
            return lengthDiff - k
        }
        
        let forwardTable = ProgressTable(size: tableSize)
        let backwardTable = ProgressTable(size: tableSize)
        
        let stepNum: Int = (maxDistance + 1) / 2 + 1
        
        for step in 0..<stepNum {
            let minK: Int
            if step <= new.count {
                minK = -step
            } else {
                minK = -(new.count - (step - new.count))
            }
            
            let maxK: Int
            if step <= old.count {
                maxK = step
            } else {
                maxK = old.count - (step - old.count)
            }
            
            for forwardK in stride(from: minK, through: maxK, by: 2) {
                let direction: ForwardDirection
                if forwardK == -step {
                    direction = .down
                } else if forwardK == step {
                    direction = .right
                } else if forwardTable[k: forwardK - 1] < forwardTable[k: forwardK + 1] {
                    direction = .down
                } else {
                    direction = .right
                }
                
                let snakeStartX: Int
                switch direction {
                case .down:
                    snakeStartX = forwardTable[k: forwardK + 1]
                case .right:
                    snakeStartX = forwardTable[k: forwardK - 1] + 1
                }
                let snakeStartY: Int = snakeStartX - forwardK
                
                var snakeEndX = snakeStartX
                var snakeEndY = snakeStartY
                
                while snakeEndX < old.count, snakeEndY < new.count {
                    if equals(oldIndex: snakeEndX, newIndex: snakeEndY) {
                        snakeEndX += 1
                        snakeEndY += 1
                    } else {
                        break
                    }
                }
                
                forwardTable[k: forwardK] = snakeEndX
                
                let backwardK = reverse(k: forwardK)
                
                let isCrossingStep = maxDistance % 2 == 1
                if isCrossingStep {
                    let isBackwardPresented = -(step-1) <= backwardK && backwardK <= (step-1)
                    if isBackwardPresented {
                        let isCrossing = forwardTable[k: forwardK] + backwardTable[k: backwardK] >= old.count
                        if isCrossing {
                            if snakeStartX == snakeEndX {
                                if step == 0 {
                                    // maxDistanceのガードがあるからここには来ない
                                    assertionFailure()
                                } else if step == 1 {
                                    assert(snakeEndX == old.count)
                                    assert(snakeEndY == new.count)
                                    assert(abs(lengthDiff) == 1)
                                    if new.count < old.count {
                                        return difference(old: old[new.count..<old.count],
                                                          new: new[new.count..<new.count])
                                    } else {
                                        return difference(old: old[old.count..<old.count],
                                                          new: new[old.count..<new.count])
                                    }
                                }
                            }
                            
                            return difference(old: old[0..<snakeStartX], new: new[0..<snakeStartY]) +
                                difference(old: old[snakeEndX..<old.count], new: new[snakeEndY..<new.count])
                        }
                    }
                }
            }
            
            for backwardK in stride(from: minK, through: maxK, by: 2) {
                let direction: BackwardDirection
                if backwardK == -step {
                    direction = .up
                } else if backwardK == step {
                    direction = .left
                } else if backwardTable[k: backwardK - 1] < backwardTable[k: backwardK + 1] {
                    direction = .up
                } else {
                    direction = .left
                }
                
                let snakeStartX: Int
                switch direction {
                case .up:
                    snakeStartX = backwardTable[k: backwardK + 1]
                case .left:
                    snakeStartX = backwardTable[k: backwardK - 1] + 1
                }
                let snakeStartY: Int = snakeStartX - backwardK
                
                var snakeEndX = snakeStartX
                var snakeEndY = snakeStartY
                
                while snakeEndX < old.count, snakeEndY < new.count {
                    if equals(oldIndex: old.count - 1 - snakeEndX,
                              newIndex: new.count - 1 - snakeEndY) {
                        snakeEndX += 1
                        snakeEndY += 1
                    } else {
                        break
                    }
                }
                
                backwardTable[k: backwardK] = snakeEndX
                
                let forwardK = reverse(k: backwardK)
                
                let isCrossingStep = maxDistance % 2 == 0
                if isCrossingStep {
                    let isForwardPresented = -step <= forwardK && forwardK <= step
                    if isForwardPresented {
                        let isCrossing = forwardTable[k: forwardK] + backwardTable[k: backwardK] >= old.count
                        if isCrossing {
                            if snakeStartX == snakeEndX {
                                if step == 0 {
                                    return []
                                }
                            }
                            
                            return difference(old: old[0..<(old.count - snakeEndX)],
                                              new: new[0..<(new.count - snakeEndY)]) +
                                difference(old: old[(old.count - snakeStartX)..<old.count],
                                           new: new[(new.count - snakeStartY)..<new.count])
                        }
                    }
                }
            }
        }
        
        fatalError("never reach here")
    }
}
