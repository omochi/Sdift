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
    equals equalsImpl: @escaping (O, N) -> Bool) -> Difference
{
    var equalCache: [CacheKey: Bool] = [:]
    
    func rawEquals(oldIndex: Int, newIndex: Int) -> Bool {
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
    
    func recurse(old: Slice<O>, new: Slice<N>) -> [Difference.Item] {
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
            let minK: Int = {
                if step <= new.count {
                    return -step
                } else {
                    return -(new.count - (step - new.count))
                }
            }()
            
            let maxK: Int = {
                if step <= old.count {
                    return step
                } else {
                    return old.count - (step - old.count)
                }
            }()
            
            for forwardK in stride(from: minK, through: maxK, by: 2) {
                let direction: ForwardDirection = {
                    if forwardK == -step {
                        return .down
                    }
                    if forwardK == step {
                        return .right
                    }
                    if forwardTable[k: forwardK - 1] < forwardTable[k: forwardK + 1] {
                        return .down
                    } else {
                        return .right
                    }
                }()
                
                let snakeStartX: Int = {
                    switch direction {
                    case .down:
                        return forwardTable[k: forwardK + 1]
                    case .right:
                        return forwardTable[k: forwardK - 1] + 1
                    }
                }()
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
                
                if maxDistance % 2 == 1 {
                    if -(step-1) <= backwardK, backwardK <= (step-1),
                        forwardTable[k: forwardK] + backwardTable[k: backwardK] >= old.count
                    {
                        return recurse(old: old[0..<snakeStartX], new: new[0..<snakeStartY]) +
                            recurse(old: old[snakeEndX..<old.count], new: new[snakeEndY..<new.count])
                    }
                }
            }
            
            for backwardK in stride(from: minK, through: maxK, by: 2) {
                let direction: BackwardDirection = {
                    if backwardK == -step {
                        return .up
                    }
                    if backwardK == step {
                        return .left
                    }
                    if backwardTable[k: backwardK - 1] < backwardTable[k: backwardK + 1] {
                        return .up
                    } else {
                        return .left
                    }
                }()
                
                let snakeStartX: Int = {
                    switch direction {
                    case .up:
                        return backwardTable[k: backwardK + 1]
                    case .left:
                        return backwardTable[k: backwardK - 1] + 1
                    }
                }()
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
                
                if maxDistance % 2 == 0 {
                    if -step <= forwardK, forwardK <= step,
                        forwardTable[k: forwardK] + backwardTable[k: backwardK] >= old.count
                    {
                        return recurse(old: old[0..<(old.count - snakeEndX)],
                                          new: new[0..<(new.count - snakeEndY)]) +
                            recurse(old: old[(old.count - snakeStartX)..<old.count],
                                       new: new[(new.count - snakeStartY)..<new.count])
                    }
                }
            }
        }
        
        fatalError("never reach here")
    }
    
    return Difference(recurse(old: Slice(elements: old,
                                         offset: 0,
                                         count: old.count),
                              new: Slice(elements: new,
                                         offset: 0,
                                         count: new.count)))
}

