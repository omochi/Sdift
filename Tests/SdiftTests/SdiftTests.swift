import XCTest
@testable import Sdift

extension Difference {
    public func reconstruct<E>(old: [E],
                               new: [E],
                               append: (E) -> Void)
    {
        var oldIndex = 0
        for item in items {
            while oldIndex < item.oldIndex {
                append(old[oldIndex])
                oldIndex += 1
            }
            switch item {
            case .remove:
                oldIndex += 1
            case .insert(oldIndex: _, newIndex: let newIndex):
                append(new[newIndex])
            }
        }
        while oldIndex < old.count {
            append(old[oldIndex])
            oldIndex += 1
        }
    }
}

final class SdiftTests: XCTestCase {
    func testDifference0() {
        let old = ""
        let new = ""
        let diff = difference(old: old, new: new)
        XCTAssertEqual(diff.items.count, 0)
    }
    
    func testDifference1() {
        let old = "a"
        let new = ""
        let diff = difference(old: old, new: new)
        XCTAssertEqual(diff.items.count, 1)
        XCTAssertEqual(diff.items[0], .remove(oldIndex: 0))
    }
    
    func testDifference2() {
        let old = "abc"
        let new = ""
        let diff = difference(old: old, new: new)
        XCTAssertEqual(diff.items.count, 3)
        XCTAssertEqual(diff.items[0], .remove(oldIndex: 0))
        XCTAssertEqual(diff.items[1], .remove(oldIndex: 1))
        XCTAssertEqual(diff.items[2], .remove(oldIndex: 2))
    }
   
    func testDifference3() {
        let old = ""
        let new = "a"
        let diff = difference(old: old, new: new)
        XCTAssertEqual(diff.items.count, 1)
        XCTAssertEqual(diff.items[0], .insert(oldIndex: 0, newIndex: 0))
    }
    
    func testDifference4() {
        let old = ""
        let new = "abc"
        let diff = difference(old: old, new: new)
        XCTAssertEqual(diff.items.count, 3)
        XCTAssertEqual(diff.items[0], .insert(oldIndex: 0, newIndex: 0))
        XCTAssertEqual(diff.items[1], .insert(oldIndex: 0, newIndex: 1))
        XCTAssertEqual(diff.items[2], .insert(oldIndex: 0, newIndex: 2))
    }
    
    func testDifference5() {
        let old = "abc"
        let new = "def"
        let diff = difference(old: old, new: new)
        XCTAssertEqual(diff.items.count, 6)
        XCTAssertEqual(diff.items[0], .remove(oldIndex: 0))
        XCTAssertEqual(diff.items[1], .remove(oldIndex: 1))
        XCTAssertEqual(diff.items[2], .remove(oldIndex: 2))
        XCTAssertEqual(diff.items[3], .insert(oldIndex: 3, newIndex: 0))
        XCTAssertEqual(diff.items[4], .insert(oldIndex: 3, newIndex: 1))
        XCTAssertEqual(diff.items[5], .insert(oldIndex: 3, newIndex: 2))
    }
    
    func testDifference6() {
        let old = "abcabba"
        let new = "cbabac"
        let diff = difference(old: old, new: new)
        XCTAssertEqual(diff.items.count, 5)
        XCTAssertEqual(diff.items[0], .remove(oldIndex: 0))
        XCTAssertEqual(diff.items[1], .insert(oldIndex: 1, newIndex: 0))
        XCTAssertEqual(diff.items[2], .remove(oldIndex: 2))
        XCTAssertEqual(diff.items[3], .remove(oldIndex: 5))
        XCTAssertEqual(diff.items[4], .insert(oldIndex: 7, newIndex: 5))
    }
    
    func testDifference7() {
        let old = "abgdef"
        let new = "gh"
        let diff = difference(old: old, new: new)
        XCTAssertEqual(diff.items.count, 6)
        XCTAssertEqual(diff.items[0], .remove(oldIndex: 0))
        XCTAssertEqual(diff.items[1], .remove(oldIndex: 1))
        XCTAssertEqual(diff.items[2], .remove(oldIndex: 3))
        XCTAssertEqual(diff.items[3], .remove(oldIndex: 4))
        XCTAssertEqual(diff.items[4], .insert(oldIndex: 5, newIndex: 1))
        XCTAssertEqual(diff.items[5], .remove(oldIndex: 5))
    }
    
    func assertReconstruct(old: String, new: String) {
        let diff = difference(old: old, new: new)
        var renew: String = ""
        diff.reconstruct(old: Array(old), new: Array(new)) { renew.append($0) }
        XCTAssertEqual(new, renew)
    }
    
    func testReconstruct() {
        // 0x0
        assertReconstruct(old: "", new: "")
        // 1x0
        assertReconstruct(old: "a", new: "")
        // 0x1
        assertReconstruct(old: "", new: "a")
        // 1x1
        assertReconstruct(old: "a", new: "a")
        assertReconstruct(old: "a", new: "b")
        // 2x0
        assertReconstruct(old: "ab", new: "")
        // 2x1
        assertReconstruct(old: "ab", new: "c")
        assertReconstruct(old: "ab", new: "a")
        assertReconstruct(old: "ab", new: "b")
        assertReconstruct(old: "aa", new: "a")
        // 0x2
        assertReconstruct(old: "", new: "ab")
        // 1x2
        assertReconstruct(old: "a", new: "bc")
        assertReconstruct(old: "a", new: "ab")
        assertReconstruct(old: "a", new: "ba")
        assertReconstruct(old: "a", new: "aa")
        
        // 2x2 (0)
        assertReconstruct(old: "ab", new: "cd")
        // 2x2 (1)
        assertReconstruct(old: "ab", new: "ad")
        assertReconstruct(old: "ab", new: "ca")
        assertReconstruct(old: "ab", new: "bd")
        assertReconstruct(old: "ab", new: "cb")
        // 2x2 (2)
        assertReconstruct(old: "aa", new: "ad")
        assertReconstruct(old: "ab", new: "ab")
        assertReconstruct(old: "ab", new: "aa")
        
        assertReconstruct(old: "ab", new: "bb")
        assertReconstruct(old: "ab", new: "ba")
        
        assertReconstruct(old: "aa", new: "ba")
        // 2x2 (3)
        assertReconstruct(old: "aa", new: "ab")
        assertReconstruct(old: "aa", new: "ba")
        assertReconstruct(old: "ab", new: "aa")
        assertReconstruct(old: "ba", new: "aa")
        // 2x2 (4)
        assertReconstruct(old: "aa", new: "aa")

        //
        assertReconstruct(old: "abcabba", new: "cbabac")
        assertReconstruct(old: "abgdef", new: "gh")
    }
    
    func assertApply(old: String, new: String) {
        var old = Array(old)
        let new = Array(new)
        let diff = difference(old: old, new: new)
        diff.apply(new: new,
                   insert: { (index, item) in
                    old.insert(item, at: index) },
                   update: { (index, item) in
                    XCTAssertEqual(old[index], item) },
                   remove: { (index) in
                    old.remove(at: index) })
        XCTAssertEqual(old, new)
    }
    
    func testApply() {
        assertApply(old: "a", new: "ab")
        assertApply(old: "a", new: "ba")
        assertApply(old: "abcabba", new: "cbabac")
        assertApply(old: "abgdef", new: "gh")
    }

    static var allTests = [
        ("testDifference0", testDifference0),
        ("testDifference1", testDifference1),
        ("testDifference2", testDifference2),
        ("testDifference3", testDifference3),
        ("testDifference4", testDifference4),
        ("testDifference5", testDifference5),
        ("testDifference6", testDifference6),
        ("testDifference7", testDifference7),
        ("testReconstruct", testReconstruct),
        ("testApply", testApply),
    ]
}
