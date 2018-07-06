import Foundation


private func timeSpecFrom(date: Date) -> timespec? {
    guard date.timeIntervalSinceNow > 0 else {
        return nil
    }
    
    let nsecPerSec: Int64 = 1_000_000_000
    let interval = date.timeIntervalSince1970
    let intervalNS = Int64(interval * Double(nsecPerSec))

    return timespec(tv_sec: Int(intervalNS / nsecPerSec), tv_nsec: Int(intervalNS % nsecPerSec))
}


open class RecursiveCondition: NSObject, NSLocking {
    private var mutex = pthread_mutex_t()
    private var cond = pthread_cond_t()

    public override init() {        
        var mattr = pthread_mutexattr_t()

        pthread_mutexattr_init(&mattr);
        pthread_mutexattr_settype(&mattr, Int32(PTHREAD_MUTEX_RECURSIVE));
        pthread_mutex_init(&mutex, &mattr);
        pthread_mutexattr_destroy(&mattr);
        
        pthread_cond_init(&cond, nil);
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
        pthread_cond_destroy(&cond)
    }
    
    open func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    open func unlock() {
        pthread_mutex_unlock(&mutex)
    }
    
    open func wait() {
        pthread_cond_wait(&cond, &mutex)
    }

    open func wait(until limit: Date) -> Bool {
        guard var timeout = timeSpecFrom(date: limit) else {
            return false
        }
        return pthread_cond_timedwait(&cond, &mutex, &timeout) == 0
    }
    
    open func signal() {
        pthread_cond_signal(&cond)
    }
    
    open func broadcast() {
        pthread_cond_broadcast(&cond)
    }
    
    open var name: String?
}