//
//  Primitive.swift
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit

class Primitive {
    
    static var sharedDevice: MTLDevice!
    static var sharedAllocator: MTKMeshBufferAllocator?
    
    static func makeCube(device: MTLDevice = sharedDevice,
                         size: Float) -> MDLMesh {
        let allocator = sharedAllocator ?? MTKMeshBufferAllocator(device: device)
        let mesh = MDLMesh(boxWithExtent: [size, size, size],
                           segments: [5, 5, 5],
                           inwardNormals: false,
                           geometryType: .triangles,
                           allocator: allocator)
        return mesh
    }
    
    static func makeFromUrl(device: MTLDevice = sharedDevice,
                            url: URL,
                            vertexDescriptor: MDLVertexDescriptor) -> MDLMesh {
        
        let asset = MDLAsset(url: url,
                             vertexDescriptor: vertexDescriptor,
                             bufferAllocator: sharedAllocator)
        let mdlMesh = asset.childObjects(of: MDLMesh.self).first as! MDLMesh
        
//        mdlMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal,
//                           creaseThreshold: 1.0)
        mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                tangentAttributeNamed: MDLVertexAttributeTangent,
                                bitangentAttributeNamed: MDLVertexAttributeBitangent)
        
        
        return mdlMesh
    }
}
