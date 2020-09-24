//
//  Material.swift
//  IronMaiden
//
//  Created by Giantwow on 21/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit

class Material {
    struct Textures {
        
        var textures: [MTLTexture?] = [MTLTexture?](repeating: nil, count: TexturePositionCount.int)
        
        var diffuse: MTLTexture?    {
            get { self.textures[TexturePositionDiffuse.int] }
            set { self.textures[TexturePositionDiffuse.int] = newValue }
        }
        var specular: MTLTexture?   {
            get { self.textures[TexturePositionSpecular.int] }
            set { self.textures[TexturePositionSpecular.int] = newValue }
        }
        var occlusion: MTLTexture?  {
            get { self.textures[TexturePositionOcclusion.int] }
            set { self.textures[TexturePositionOcclusion.int] = newValue }
        }
        var shininess: MTLTexture?  {
            get { self.textures[TexturePositionShininess.int] }
            set { self.textures[TexturePositionShininess.int] = newValue }
        }
        var roughness: MTLTexture?  {
            get { self.textures[TexturePositionRoughness.int] }
            set { self.textures[TexturePositionRoughness.int] = newValue }
        }
        var metallic: MTLTexture?   {
            get { self.textures[TexturePositionMetallic.int] }
            set { self.textures[TexturePositionMetallic.int] = newValue }
        }
        var normal: MTLTexture?     {
            get { self.textures[TexturePositionNormal.int] }
            set { self.textures[TexturePositionNormal.int] = newValue }
        }
        
    }
    var shaderMaterial: ShaderMaterial = ShaderMaterial()
    
    var diffuseColor: vector_float3 {
        get { self.shaderMaterial.diffuseColor }
        set { self.shaderMaterial.diffuseColor = newValue }
    }
    var specularColor: vector_float3 {
        get { self.shaderMaterial.specularColor }
        set { self.shaderMaterial.specularColor = newValue }
    }
    var ambiantOcclusion: vector_float3 {
        get { self.shaderMaterial.ambiantOcclusion }
        set { self.shaderMaterial.ambiantOcclusion = newValue }
    }
    var shininess: Float {
        get { self.shaderMaterial.shininess }
        set { self.shaderMaterial.shininess = newValue }
    }
    var roughness: Float {
        get { self.shaderMaterial.roughness }
        set { self.shaderMaterial.roughness = newValue }
    }
    var metallic: Float {
        get { self.shaderMaterial.metallic }
        set { self.shaderMaterial.metallic = newValue }
    }
    
    var textures: Textures = Textures()
    
    var colorTextureOffset: vector_float2 = .zero { didSet { self.updateColorTextureTransform() } }
    var colorTextureScale: vector_float2 = .one { didSet { self.updateColorTextureTransform() } }
    var colorTextureRotation: Float = 0 { didSet { self.updateColorTextureTransform() } }
    
    var normalTextureOffset: vector_float2 = .zero { didSet { self.updateNormalTextureTransform() } }
    var normalTextureScale: vector_float2 = .one { didSet { self.updateNormalTextureTransform() } }
    var normalTextureRotation: Float = 0 { didSet { self.updateNormalTextureTransform() } }
    
    init() {
        self.updateColorTextureTransform()
        self.updateNormalTextureTransform()
    }
    
    func updateNormalTextureTransform() {
        self.shaderMaterial.normalTextureTransform =
            float3x3(translation: self.normalTextureOffset)
            * float3x3(rotation: self.normalTextureRotation)
            * float3x3(scaling: self.normalTextureScale)
    }
    
    func updateColorTextureTransform() {
        self.shaderMaterial.colorTextureTransform =
            float3x3(translation: self.colorTextureOffset)
            * float3x3(rotation: self.colorTextureRotation)
            * float3x3(scaling: self.colorTextureScale)
    }
    
    static func loadTexture(device: MTLDevice = Scene.sharedDevice,
                            url: URL) throws -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft,
            .SRGB: false,
            .generateMipmaps: NSNumber(booleanLiteral: true),
        ]
        
        let texture = try textureLoader.newTexture(URL: url, options: textureLoaderOptions)
        return texture
    }
    
    static func loadTexture(device: MTLDevice = Scene.sharedDevice,
                            name: String) throws -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft,
            .SRGB: false,
            .generateMipmaps: NSNumber(booleanLiteral: true),
        ]
        
        let texture = try textureLoader.newTexture(name: name,
                                                   scaleFactor: 1.0,
                                                   bundle: .main,
                                                   options: textureLoaderOptions)
        return texture
    }
    
}
