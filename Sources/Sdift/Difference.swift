import Foundation

public struct Difference {
    public enum Item : Equatable {
        case insert(oldIndex: Int, newIndex: Int)
        case remove(oldIndex: Int)
        
        var oldIndex: Int {
            switch self {
                case .insert(oldIndex: let x, newIndex: _),
                     .remove(oldIndex: let x):
                return x
            }
        }
    }
    
    public var items: [Item]
    
    public init(_ items: [Item]) {
        self.items = items
    }

    public func apply<NC: Collection>(new: NC,
                                      insert: (Int, NC.Element) -> Void,
                                      update: (Int, NC.Element) -> Void,
                                      remove: (Int) -> Void)
    {
        apply(new: Array(new),
              insert: insert,
              update: update,
              remove: remove)
    }
    
    public func apply<N>(new: [N],
                         insert: (Int, N) -> Void,
                         update: (Int, N) -> Void,
                         remove: (Int) -> Void)
    {
        var oldIndex = 0
        var oldIndexOffset = 0
        var newIndex = 0
        for item in items {
            while oldIndex < item.oldIndex {
                update(oldIndex + oldIndexOffset, new[newIndex])
                oldIndex += 1
                newIndex += 1
            }
            switch item {
            case .remove:
                remove(oldIndex + oldIndexOffset)
                oldIndex += 1
                oldIndexOffset -= 1
            case .insert(oldIndex: _, newIndex: _):
                insert(oldIndex + oldIndexOffset, new[newIndex])
                oldIndexOffset += 1
                newIndex += 1
            }
        }
        while newIndex < new.count {
            update(oldIndex + oldIndexOffset, new[newIndex])
            oldIndex += 1
            newIndex += 1
        }
    }
}
