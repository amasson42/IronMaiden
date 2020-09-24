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

