//
//  Mesh.swift
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit

struct MeshLoadingOptions: OptionSet {
    var rawValue: UInt32
    
    static let generateNormal =     MeshLoadingOptions(rawValue: 1 << 0)
    static let generateTangent =    MeshLoadingOptions(rawValue: 1 << 1)
}

class ModelMesh {
    
    let mtkMesh: MTKMesh
    let submeshes: [Submesh]
    
    var pipelineState: MTLRenderPipelineState?
    static var standardPipelineState: MTLRenderPipelineState!
    static var standardVertexDescriptor: MDLVertexDescriptor!
    static var sharedBufferAllocator: MTKMeshBufferAllocator!
    
    static func initGlobalDevice(_ device: MTLDevice, forPixelFormat pixelFormat: MTLPixelFormat) {
        Self.initStandardVertexDescriptor()
        Self.initStandardPipelineState(device: device, forPixelFormat: pixelFormat)
        self.sharedBufferAllocator = MTKMeshBufferAllocator(device: device)
        Submesh.initGlobalDevice(device, forPixelFormat: pixelFormat)
    }
    
    fileprivate static func initStandardPipelineState(device: MTLDevice, forPixelFormat pixelFormat: MTLPixelFormat) {
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(Self.standardVertexDescriptor)
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        Self.standardPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    fileprivate static func initStandardVertexDescriptor() {
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
        
        Self.standardVertexDescriptor = vertexDescriptor
    }
    
    init(url: URL, options: MeshLoadingOptions = []) throws {
        let asset = MDLAsset(url: url, vertexDescriptor: Self.standardVertexDescriptor, bufferAllocator: Self.sharedBufferAllocator)
        let mdlMesh = asset.childObjects(of: MDLMesh.self).first as! MDLMesh
        
        if options.contains(.generateNormal) {
            mdlMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 1.0)
        }
        if options.contains(.generateTangent) {
            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    tangentAttributeNamed: MDLVertexAttributeTangent,
                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
        }
        
        self.mtkMesh = try MTKMesh(mesh: mdlMesh, device: Scene.sharedDevice)
        self.submeshes = zip(mdlMesh.submeshes!, mtkMesh.submeshes).map { mesh in
            Submesh(mdlSubmesh: mesh.0 as! MDLSubmesh, mtkSubmesh: mesh.1)
        }
    }
    
    func setMaterial(_ material: Material) {
        self.submeshes.forEach {
            $0.material = material
        }
    }
    
    class Submesh {
        
        var mtkSubmesh: MTKSubmesh
        var material: Material?
        static var standardMaterial: Material = Material()
        static var standardSamplerState: MTLSamplerState!
        
        static func initGlobalDevice(_ device: MTLDevice, forPixelFormat pixelFormat: MTLPixelFormat) {
            let samplerDescriptor = MTLSamplerDescriptor()
            samplerDescriptor.minFilter = .linear
            samplerDescriptor.magFilter = .linear
            samplerDescriptor.sAddressMode = .repeat
            samplerDescriptor.tAddressMode = .repeat
            Self.standardSamplerState = device.makeSamplerState(descriptor: samplerDescriptor)
        }
        
        init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
            self.mtkSubmesh = mtkSubmesh
            self.material = try? Material(mdlMaterial: mdlSubmesh.material)
        }
    }
    
}

extension Material {
    convenience init(mdlMaterial: MDLMaterial?) throws {
        self.init()
        guard let material = mdlMaterial else {
            return
        }
        
        func propertyFloat3(with semantic: MDLMaterialSemantic,
                            path: ReferenceWritableKeyPath<Material, vector_float3>) {
            if let mdlValue = material.property(with: semantic),
               mdlValue.type == .float3 {
                self[keyPath: path] = mdlValue.float3Value
            }
        }
        func propertyFloat(with semantic: MDLMaterialSemantic,
                           path: ReferenceWritableKeyPath<Material, Float>) {
            if let mdlValue = material.property(with: semantic),
               mdlValue.type == .float {
                self[keyPath: path] = mdlValue.floatValue
            }
        }
        
        propertyFloat3(with: .baseColor, path: \.diffuseColor)
        propertyFloat3(with: .specular, path: \.specularColor)
        propertyFloat3(with: .ambientOcclusion, path: \.ambiantOcclusion)
        propertyFloat(with: .specularExponent, path: \.shininess)
        propertyFloat(with: .roughness, path: \.roughness)
        propertyFloat(with: .metallic, path: \.metallic)
        
        func property(with semantic: MDLMaterialSemantic) -> MTLTexture? {
            guard let property = material.property(with: semantic),
                  property.type == .string,
                  let filename = property.stringValue,
                  let url = Bundle.main.url(forResource: "ModelAssets.scnassets/\(filename)", withExtension: nil),
                  let texture = try? Material.loadTexture(url: url) else {
                return nil
            }
            return texture
        }
        
        self.textures.diffuse = property(with: MDLMaterialSemantic.baseColor)
        self.textures.specular = property(with: MDLMaterialSemantic.specular)
        self.textures.occlusion = property(with: MDLMaterialSemantic.ambientOcclusion)
        self.textures.shininess = property(with: MDLMaterialSemantic.specularExponent)
        self.textures.roughness = property(with: MDLMaterialSemantic.roughness)
        self.textures.metallic = property(with: MDLMaterialSemantic.metallic)
        self.textures.normal = property(with: MDLMaterialSemantic.objectSpaceNormal)
    }
}

extension ModelMesh: Renderable {
    
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
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: BufferIndexUniforms.int)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: BufferIndexUniforms.int)
        
        encoder.setFragmentBytes(&scene.frameLights,
                                 length: MemoryLayout<ShaderLight>.stride * scene.frameLights.count,
                                 index: BufferIndexLights.int)
        
        var lightCount = UInt32(scene.frameLights.count)
        encoder.setFragmentBytes(&lightCount, length: MemoryLayout<UInt32>.size, index: BufferIndexLightsCount.int)
        
        for submesh in self.submeshes {
            let usedMaterial = submesh.material ?? Submesh.standardMaterial
            
            encoder.setFragmentBytes(&usedMaterial.shaderMaterial, length: MemoryLayout<ShaderMaterial>.size, index: BufferIndexMaterial.int)
            
            let textures = usedMaterial.textures.textures
            let texturesRange = TexturePositionDiffuse.int ..< TexturePositionDiffuse.int + textures.count
            encoder.setFragmentTextures(textures, range: texturesRange)
            
            encoder.setFragmentSamplerState(Submesh.standardSamplerState, index: TexturePositionDiffuse.int)
            encoder.setFragmentSamplerState(Submesh.standardSamplerState, index: TexturePositionNormal.int)
            
            encoder.drawIndexedPrimitives(type: submesh.mtkSubmesh.primitiveType,
                                          indexCount: submesh.mtkSubmesh.indexCount,
                                          indexType: submesh.mtkSubmesh.indexType,
                                          indexBuffer: submesh.mtkSubmesh.indexBuffer.buffer,
                                          indexBufferOffset: submesh.mtkSubmesh.indexBuffer.offset)
        }
        
    }
    
}
