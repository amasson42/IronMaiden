//
//  StandardExtensions.swift
//  IronMaiden
//
//  Created by Vistory Group on 09/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import Foundation

/// Protocol assuming that the object can be initialized with no parameters
public protocol EmptyInitializable {
    init()
}

extension Bool: EmptyInitializable {}
extension Int: EmptyInitializable {}
extension Double: EmptyInitializable {}
extension Float: EmptyInitializable {}
extension String: EmptyInitializable {}
extension Array: EmptyInitializable {}
extension Data: EmptyInitializable {}
extension Dictionary: EmptyInitializable {}

/// Create and object stocked in the UserDefaults standard with the key
/// Specific behavior for Bool, Int and String
@propertyWrapper
public struct UserDefault<T: EmptyInitializable> {
    let key: String
    
    init(_ key: String) {
        self.key = key
    }
    
    public var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? T()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

/// Container of only one value referenced by a weak pointer
/// The main purpose is to make an array of weak pointers
public struct WeakBox<RefType: AnyObject> {
    public private(set) weak var ref: RefType?
}

extension WeakBox: Equatable where RefType: Equatable {}
extension WeakBox: Hashable where RefType: Hashable {}

extension ClosedRange where Element == Int {
    func intIndex(of element: Element) -> Int {
        if element < self.lowerBound {
            return -1
        } else if element > self.upperBound {
            return self.upperBound - self.lowerBound + 1
        } else {
            return element - self.lowerBound
        }
    }
}

extension Array {
    
    public subscript(safe index: Self.Index) -> Element? {
        return self.indices.contains(index) ? self[index] : nil
    }
    
    public subscript(_ indices: [Index]) -> Self {
        var ret = Self()
        ret.reserveCapacity(indices.count)
        indices.forEach {
            ret.append(self[$0])
        }
        return ret
    }
    
    public func sorted(by areInIncreasingOrder: (Element, Element) throws -> Bool,
                       withIndicesFor indexFor: (Element) throws -> Index?) rethrows -> [Element] {
        return try self.sorted { (lhs, rhs) -> Bool in
            let (li, ri) = try (indexFor(lhs), indexFor(rhs))
            return li != nil ? (ri != nil ? li! < ri! : true) : (ri != nil ? false : try areInIncreasingOrder(lhs, rhs))
        }
    }
}

extension Dictionary {
    
    public subscript(_ indices: [Key]) -> Self {
        var ret: Self = [:]
        ret.reserveCapacity(indices.count)
        indices.forEach {
            ret[$0] = self[$0]
        }
        return ret
    }
    
}

extension Bool {
    /// A float value that is 1.0 for true and 0.0 for false
    var float: Float {
        self ? 1.0 : 0.0
    }
}

extension RawRepresentable where RawValue: BinaryInteger {
    /// A simple cast of the value into an int
    var int: Int {
        Int(self.rawValue)
    }
}
