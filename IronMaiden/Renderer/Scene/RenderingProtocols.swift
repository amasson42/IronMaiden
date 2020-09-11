//
//  RenderingProtocols.swift
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit

protocol Renderable: class {
    
    func render(encoder: MTLRenderCommandEncoder, scene: Scene, uniforms: Uniforms)
    
}

protocol Texturable {
    
}

extension Texturable {
    static func loadTexture(device: MTLDevice = Primitive.sharedDevice,
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
    
    static func loadTexture(device: MTLDevice = Primitive.sharedDevice,
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
