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

}
