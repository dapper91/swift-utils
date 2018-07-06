import Foundation


protocol Queue {
    associatedtype ValueType

    var count: Int { get }
    var isEmpty: Bool { get }

    var front: ValueType? { get }
    var back: ValueType? { get }

    func pop() -> ValueType?
    func push(_ value: ValueType)
}


public class SimpleQueue<T>: Queue {
    typealias ValueType = T

    private var data = [T?]()
    private var headIdx = 0

    public var isEmpty: Bool 
    {
        return count == 0
    }

    public var count: Int 
    {
        return data.count - headIdx
    }

    public func push(_ value: T) 
    {
        data.append(value)
    }

    public func pop() -> T? 
    {
        guard headIdx < data.count, let value = data[headIdx] else { 
            return nil 
        }

        data[headIdx] = nil
        headIdx += 1

        let loadFactor = Double(data.count - headIdx)/Double(data.count)
        if loadFactor < 0.25 {
            data.removeFirst(headIdx)
            headIdx = 0
        }

        return value
    }

    public var front: T? 
    {
        return isEmpty ? nil : data[headIdx]
    }

    public var back: T? 
    {
        return data.last ?? nil
    }
}


enum QueueError: Error {
    case queueIsEmpty()
    case queueIsFull(maxSize: Int)
    case timeoutHasBeenReached(timeout: TimeInterval)
}


class BoundedQueue<T>: SimpleQueue<T> {
    private var queueMaxSize = Int.max

    var maxSize: Int
    { 
        return queueMaxSize
    }

    var isFull: Bool 
    {
        return count >= maxSize
    }

    init(maxSize ms: Int = Int.max)
    {
        queueMaxSize = ms
    }

    public func tryPop() throws -> T 
    {
        guard let value = pop() else {
            throw QueueError.queueIsEmpty()    
        }

        return value
    }

    public func tryPush(_ value: T) throws 
    {        
        guard count < maxSize else {
            throw QueueError.queueIsFull(maxSize: maxSize)
        }
        push(value)
    }
}


class SyncronizedQueue<T>: BoundedQueue<T> {        
    private var cond = RecursiveCondition()

    override var count: Int 
    {
        defer { cond.unlock() }
        cond.lock()

        return super.count
    }
    
    override var isEmpty: Bool 
    {
        defer { cond.unlock() }
        cond.lock()

        return super.isEmpty
    }

    override var isFull: Bool 
    {
        defer { cond.unlock() }
        cond.lock()

        return super.isFull
    }

    override var front: ValueType? 
    {
        defer { cond.unlock() }
        cond.lock()

        return super.front
    }
    
    override var back: ValueType? 
    {
        defer { cond.unlock() }
        cond.lock()

        return super.back
    }

    override func push(_ value: T)
    {
        defer { cond.unlock() }
        cond.lock()

        super.push(value)
        cond.signal()
    }

    func push(_ value: T, waiting timeout: TimeInterval) throws
    {
        defer { cond.unlock() }
        cond.lock()

        while (isFull) {
            if !cond.wait(until: Date(timeIntervalSinceNow: timeout)) {
                throw QueueError.timeoutHasBeenReached(timeout: timeout)
            }
        }

        return super.push(value)
    }

    override func pop() -> T?
    {
        defer { cond.unlock() }
        cond.lock()

        return super.pop()
    }

    func pop(waiting timeout: TimeInterval) throws -> T
    {
        defer { cond.unlock() }
        cond.lock()

        while (isEmpty) {
            if !cond.wait(until: Date(timeIntervalSinceNow: timeout)) {
                throw QueueError.timeoutHasBeenReached(timeout: timeout)
            }
        }

        return super.pop()!
    }

    override public func tryPop() throws -> T 
    {
        defer { cond.unlock() }
        cond.lock()

        guard let value = pop() else {
            throw QueueError.queueIsEmpty()    
        }

        return value
    }

    override public func tryPush(_ value: T) throws 
    {
        defer { cond.unlock() }
        cond.lock()

        guard count < maxSize else {
            throw QueueError.queueIsFull(maxSize: maxSize)
        }
        push(value)
    }
}