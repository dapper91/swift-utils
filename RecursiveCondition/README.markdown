# NSRecursiveCondition

A recursive version of swift Foundation NSCondition (condition variable).
More info about a non-recursive version can be found here: https://developer.apple.com/documentation/foundation/nscondition


Example:

```swift
class MyClass {
    private var cond = RecursiveCondition()

    func firstFunc()
    {
        cond.lock()
        defer { cond.unlock() }

        secondFunc()
    }

    func secondFunc()
    {
        cond.lock() // it's safe to lock the same condition variable multiple times in a single thread 
        defer { cond.unlock() }

        print("test message")
    }
}

var c = MyClass()
c.firstFunc()

```
