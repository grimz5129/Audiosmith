import XCTest
@testable import Audify

final class RingBufferTests: XCTestCase {
    func testWriteThenReadRoundTrips() {
        let rb = RingBuffer(capacity: 8)
        XCTAssertEqual(rb.write([1, 2, 3]), 3)
        var out = [Float](repeating: 0, count: 3)
        XCTAssertEqual(rb.read(into: &out, count: 3), 3)
        XCTAssertEqual(out, [1, 2, 3])
    }

    func testReadBeyondAvailableReturnsOnlyAvailable() {
        let rb = RingBuffer(capacity: 8)
        _ = rb.write([1, 2])
        var out = [Float](repeating: 0, count: 5)
        XCTAssertEqual(rb.read(into: &out, count: 5), 2)
    }

    func testWriteBeyondCapacityDropsOverflow() {
        let rb = RingBuffer(capacity: 4)
        XCTAssertEqual(rb.write([1, 2, 3, 4, 5, 6]), 4)
        XCTAssertEqual(rb.availableToRead, 4)
    }

    func testWrapAround() {
        let rb = RingBuffer(capacity: 4)
        _ = rb.write([1, 2, 3])
        var out = [Float](repeating: 0, count: 2)
        _ = rb.read(into: &out, count: 2)
        _ = rb.write([4, 5, 6])
        var out2 = [Float](repeating: 0, count: 4)
        XCTAssertEqual(rb.read(into: &out2, count: 4), 4)
        XCTAssertEqual(out2, [3, 4, 5, 6])
    }
}
