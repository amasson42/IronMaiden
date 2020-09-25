//
//  NodeTreeElement.swift
//  IronMaiden
//
//  Created by Vistory Group on 09/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import Foundation

/**
    The procotol that a class will follow if it has a parent and children of the same type as itself.
    The parent reference should be a weak variable to avoid reference cycles
 */
protocol NodeTreeElement: class {
    var parent: Self? { get set }
    var children: [Self] { get set }
}

extension NodeTreeElement {

    func add(childNode node: Self) {
        node.removeFromParent()
        self.children.append(node)
        node.parent = self
    }

    func remove(childNode node: Self) {
        self.children.removeAll { $0 === node }
        node.parent = nil
    }

    func removeFromParent() {
        self.parent?.remove(childNode: self)
        self.parent = nil
    }

    func child(matching: (Self) throws -> Bool, recursively: Bool = false) rethrows -> Self? {
        if let child = try self.children.first(where: matching) {
            return child
        }
        if recursively {
            for child in self.children {
                if let find = try child.child(matching: matching,
                                              recursively: recursively) {
                    return find
                }
            }
        }
        return nil
    }

    func childs(matching: (Self) throws -> Bool, recursively: Bool = false) rethrows -> [Self] {
        var childs: [Self] = []
        try self.children.forEach {
            if try matching($0) {
                childs.append($0)
            }
        }
        
        if recursively {
            for child in self.children {
                let finds = try child.childs(matching: matching, recursively: recursively)
                childs.append(contentsOf: finds)
            }
        }
        
        return childs
    }

    func dumpHierarchy(linePrefix: String = "") {
        if let verbuose = self as? CustomStringConvertible {
            print("\(linePrefix) \(verbuose.description)")
        } else {
            print("\(linePrefix) \(self)")
        }
        switch self.children.count {
        case 0:
            break
        case 1:
            self.children[0].dumpHierarchy(linePrefix: linePrefix + "└─")
        default:
            self.children.enumerated().forEach { (index, child) in
                if index == 0 {
                    child.dumpHierarchy(linePrefix: linePrefix + "├─")
                } else if index == self.children.count - 1 {
                    child.dumpHierarchy(linePrefix: linePrefix + "└─")
                } else {
                    child.dumpHierarchy(linePrefix: linePrefix + "├─")
                }
            }
        }
//        "│├─┬└"
    }
}
