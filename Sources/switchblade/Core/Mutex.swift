//    MIT License
//
//    Copyright (c) 2018 Veldspar Team
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation

/// A recursive mutex with a stable, race-free public API.
///
/// Backed by `NSRecursiveLock`, which is safe to acquire repeatedly from the
/// same thread without deadlocking. This replaces an earlier implementation
/// that read a shared `Thread?` field outside of any synchronization (a data
/// race that could cause two threads to enter the critical section
/// concurrently — observed as `SQLITE_MISUSE` when used to guard a SQLite
/// connection).
public final class Mutex {

    private let lock = NSRecursiveLock()

    public init() {
        // Aid debugging in stack traces / Instruments.
        lock.name = "Switchblade.Mutex.\(UUID().uuidString.lowercased())"
    }

    @inline(__always)
    public func mutex(_ closure: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        closure()
    }

    @inline(__always)
    public func throwingMutex(_ closure: () throws -> Void) throws {
        lock.lock()
        defer { lock.unlock() }
        try closure()
    }

    @inline(__always)
    public func mutex<T>(_ closure: () -> T?) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return closure()
    }

    @inline(__always)
    public func throwingMutex<T>(_ closure: () throws -> T?) throws -> T? {
        lock.lock()
        defer { lock.unlock() }
        return try closure()
    }

}

