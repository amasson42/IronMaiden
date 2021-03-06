//
//  Scene.swift
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit

public class Scene {
    
    static var sharedDevice: MTLDevice!
    let device: MTLDevice
    var aspectRatio: Float = 1.0
    struct Time {
        var elapsedTime: TimeInterval = 0
        var deltaTime: TimeInterval = 0
        var deltaAnimation: TimeInterval = 0
    }
    var time = Time()
    
    var rootNode: Node = Node()
    var cameraNode: Node?
    
    var frameLights: [ShaderLight] = []
    private let depthStencilState: MTLDepthStencilState
    
    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) {
        self.device = device
        self.rootNode.name = "root"
        do {
            let descriptor = MTLDepthStencilDescriptor()
            descriptor.depthCompareFunction = .less
            descriptor.isDepthWriteEnabled = true
            self.depthStencilState = device.makeDepthStencilState(descriptor: descriptor)!
        }
        
        if Self.sharedDevice == nil {
            Self.initGlobalDevice(device: device, forPixelFormat: colorPixelFormat)
        }
        
    }
    
    fileprivate static func initGlobalDevice(device: MTLDevice, forPixelFormat pixelFormat: MTLPixelFormat) {
        Scene.sharedDevice = device
        ModelMesh.initGlobalDevice(device, forPixelFormat: pixelFormat)
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
