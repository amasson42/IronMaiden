//
//  Node.swift
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import Metal

final class Node: NodeTreeElement, EmptyInitializable {
    
    // MARK: - NodeTreeElement
    weak var parent: Node?
    var children: [Node] = []
    
    // MARK: - Node General Usage
    
    var isActive: Bool = true
    var name: String = "<node>"
    var transform: Transform = Transform()
    var worldTransformMatrix: simd_float4x4 {
        let localMatrix = self.transform.matrix()
        if let parent = self.parent {
            return parent.worldTransformMatrix * localMatrix
        } else {
            return localMatrix
        }
    }
    func relativeTransformMatrix(toNode node: Node) -> simd_float4x4 {
        return .identity() // FIXME: do that
    }
    
    // MARK: - Node Functionalities
    
    var renderables: [Renderable] = []
    var camera: Camera?
    var light: Light?
    
    func add(renderable: Renderable) {
        self.renderables.append(renderable)
    }
    
}

extension Node: Renderable {
    
    func render(encoder: MTLRenderCommandEncoder, scene: Scene, uniforms: Uniforms) {
        
        var localUniforms = uniforms
        localUniforms.modelMatrix *= self.transform.matrix()
        
        for renderable in self.renderables {
            renderable.render(encoder: encoder, scene: scene, uniforms: localUniforms)
        }
        
        for child in self.children {
            child.render(encoder: encoder, scene: scene, uniforms: localUniforms)
        }
        
    }
    
}
