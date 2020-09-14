//
//  Scene.swift
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit

public class Scene {
    
    let device: MTLDevice
    var aspectRatio: Float = 1.0
    struct Time {
        var elapsedTime: TimeInterval = 0
        var deltaTime: TimeInterval = 0
    }
    var time = Time()
    
    var rootNode: Node = Node()
    var cameraNode: Node?
    
    var frameLights: [Light] = []
    private let depthStencilState: MTLDepthStencilState
    
    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) {
        self.device = device
        do {
            let descriptor = MTLDepthStencilDescriptor()
            descriptor.depthCompareFunction = .less
            descriptor.isDepthWriteEnabled = true
            self.depthStencilState = device.makeDepthStencilState(descriptor: descriptor)!
        }
        
        Primitive.sharedDevice = device
        Primitive.sharedAllocator = MTKMeshBufferAllocator(device: device)
        Mesh.initPipelines(withDevice: device, forPixelFormat: colorPixelFormat)
        
    }
    
    func render(in view: MTKView,
                renderEncoder: MTLRenderCommandEncoder) {
        
        renderEncoder.setDepthStencilState(depthStencilState)
        
        let uniforms = makeUniforms()
        
        self.rootNode.render(encoder: renderEncoder,
                             scene: self,
                             uniforms: uniforms)
        
    }
    
    func makeUniforms() -> Uniforms {
        var uniforms = Uniforms()
        if let cameraNode = self.cameraNode {
            let viewPositionMatrix = cameraNode.transform.matrix()
            uniforms.viewMatrix = viewPositionMatrix.inverse
            uniforms.cameraPosition = (viewPositionMatrix * vector_float4(0, 0, 0, 1)).xyz;
            uniforms.projectionMatrix = cameraNode.camera?.matrix ?? .identity()
        }
        return uniforms
    }
    
}
