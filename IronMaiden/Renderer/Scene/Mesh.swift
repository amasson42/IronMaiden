//
//  Mesh.swift
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit

public class Mesh: Renderable {
    let mtkMesh: MTKMesh
    let submeshes: [Submesh]
    var material: Material?
    
    var pipelineState: MTLRenderPipelineState?
    static var standardPipelineState: MTLRenderPipelineState!
    static let standardVertexDescriptor: MDLVertexDescriptor = {
        let vertexDescriptor = MDLVertexDescriptor()
        
        var offset: Int = 0
        vertexDescriptor.attributes[VertexAttributePosition.int] =
            MDLVertexAttribute(name: MDLVertexAttributePosition,
                               format: .float3,
                               offset: offset,
                               bufferIndex: BufferIndexVertices.int)
        offset += MemoryLayout<SIMD3<Float>>.stride
        
        vertexDescriptor.attributes[VertexAttributeNormal.int] =
            MDLVertexAttribute(name: MDLVertexAttributeNormal,
                               format: .float3,
                               offset: offset,
                               bufferIndex: BufferIndexVertices.int)
        offset += MemoryLayout<SIMD3<Float>>.stride
        
        vertexDescriptor.attributes[VertexAttributeUV.int] =
            MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                               format: .float2,
                               offset: offset,
                               bufferIndex: BufferIndexVertices.int)
        offset += MemoryLayout<SIMD2<Float>>.stride
        
        vertexDescriptor.attributes[VertexAttributeTangent.int] =
            MDLVertexAttribute(name: MDLVertexAttributeTangent,
                               format: .float3,
                               offset: offset,
                               bufferIndex: BufferIndexVertices.int)
        offset += MemoryLayout<SIMD3<Float>>.stride
        
        vertexDescriptor.attributes[VertexAttributeBitangent.int] =
            MDLVertexAttribute(name: MDLVertexAttributeBitangent,
                               format: .float3,
                               offset: offset,
                               bufferIndex: BufferIndexVertices.int)
        offset += MemoryLayout<SIMD3<Float>>.stride
        
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
    }()
    static let standardMaterial: Material = Material()
    static let standardSamplerState: MTLSamplerState = {
        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .repeat
        descriptor.minFilter = .linear
        descriptor.mipFilter = .linear
        let samplerState = Primitive.sharedDevice.makeSamplerState(descriptor: descriptor)!
        return samplerState
    }()
    
    static func initPipelines(withDevice device: MTLDevice,
                              forPixelFormat colorPixelFormat: MTLPixelFormat) {
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(Self.standardVertexDescriptor)
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        Self.standardPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    init(mdlMesh: MDLMesh, mtkMesh: MTKMesh) {
        self.mtkMesh = mtkMesh
        self.submeshes = zip(mdlMesh.submeshes!, mtkMesh.submeshes).map { mesh in
            Submesh(mdlSubmesh: mesh.0 as! MDLSubmesh, mtkSubmesh: mesh.1)
        }
    }
    
    func render(encoder: MTLRenderCommandEncoder, scene: Scene, uniforms: Uniforms) {
        
        guard let pipelineState = self.pipelineState ?? Self.standardPipelineState else {
            return
        }
        encoder.setRenderPipelineState(pipelineState)
        
        for (index, vertexBuffer) in self.mtkMesh.vertexBuffers.enumerated() {
            encoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: index)
        }
        
        encoder.setCullMode(.back)
        
        var uniforms = uniforms
        encoder.setVertexBytes(&uniforms,
                               length: MemoryLayout<Uniforms>.stride,
                               index: BufferIndexUniforms.int)
        
        var usedMaterial = self.material ?? Self.standardMaterial
        encoder.setFragmentBytes(&usedMaterial,
                                 length: MemoryLayout<Material>.stride,
                                 index: BufferIndexMaterial.int)
        
        encoder.setFragmentBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride,
                                 index: BufferIndexUniforms.int)
        
        encoder.setFragmentBytes(&scene.frameLights,
                                 length: MemoryLayout<Light>.stride * scene.frameLights.count,
                                 index: BufferIndexLights.int)
        
        var lightCount = UInt32(scene.frameLights.count)
        encoder.setFragmentBytes(&lightCount,
                                 length: MemoryLayout<Int>.size,
                                 index: BufferIndexLightsCount.int)
        
        encoder.setTriangleFillMode(.fill)
        for submesh in self.submeshes {
            
            encoder.setFragmentTexture(submesh.textures.diffuse,
                                       index: TexturePositionDiffuse.int)
            encoder.setFragmentSamplerState(Self.standardSamplerState,
                                            index: TexturePositionDiffuse.int)
            encoder.setFragmentTexture(submesh.textures.normal,
                                       index: TexturePositionNormal.int)
            encoder.setFragmentSamplerState(Self.standardSamplerState,
                                            index: TexturePositionNormal.int)
            
            encoder.drawIndexedPrimitives(type: submesh.mtkSubmesh.primitiveType,
                                          indexCount: submesh.mtkSubmesh.indexCount,
                                          indexType: submesh.mtkSubmesh.indexType,
                                          indexBuffer: submesh.mtkSubmesh.indexBuffer.buffer,
                                          indexBufferOffset: submesh.mtkSubmesh.indexBuffer.offset)
        }
        
    }
    
}

public class Submesh {
    var mtkSubmesh: MTKSubmesh
    
    init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
        self.mtkSubmesh = mtkSubmesh
        self.textures = Textures(material: mdlSubmesh.material)
    }
    
    struct Textures {
        var diffuse: MTLTexture?
        var normal: MTLTexture?
    }
    var textures: Textures
}

private extension Submesh.Textures {
    init(material: MDLMaterial?) {
        func property(with semantic: MDLMaterialSemantic) -> MTLTexture? {
            guard let property = material?.property(with: semantic),
                property.type == .string,
                let filename = property.stringValue,
                let url = Bundle.main.url(forResource: "ModelAssets.scnassets/\(filename)", withExtension: nil),
                let texture = try? Submesh.loadTexture(url: url) else {
                    return nil
            }
            return texture
        }
        self.diffuse = property(with: MDLMaterialSemantic.baseColor)
        self.normal = property(with: MDLMaterialSemantic.objectSpaceNormal)
    }
}

extension Submesh: Texturable {
    
}
