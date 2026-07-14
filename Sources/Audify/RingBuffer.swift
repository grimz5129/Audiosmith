import Foundation

final class RingBuffer {
    private var storage: [Float]
    private let capacity: Int
    private var head = 0
    private var tail = 0
    private var count = 0
    private let lock = NSLock()

    init(capacity: Int) {
        self.capacity = capacity
        storage = [Float](repeating: 0, count: capacity)
    }

    var availableToRead: Int {
        lock.lock(); defer { lock.unlock() }
        return count
    }

    func write(_ samples: [Float]) -> Int {
        lock.lock(); defer { lock.unlock() }
        let writable = min(samples.count, capacity - count)
        for i in 0..<writable {
            storage[tail] = samples[i]
            tail = (tail + 1) % capacity
        }
        count += writable
        return writable
    }

    func read(into buffer: inout [Float], count requested: Int) -> Int {
        lock.lock(); defer { lock.unlock() }
        let readable = min(requested, count, buffer.count)
        for i in 0..<readable {
            buffer[i] = storage[head]
            head = (head + 1) % capacity
        }
        count -= readable
        return readable
    }
}
