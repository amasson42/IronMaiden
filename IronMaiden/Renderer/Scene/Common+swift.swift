//
//  Common+swift.swift
//  IronMaiden
//
//  Created by Vistory Group on 09/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit

extension Uniforms {
    init() {
        self.init(modelMatrix: .identity(),
                  viewMatrix: .identity(),
                  projectionMatrix: .identity(),
                  cameraPosition: .zero)
    }
}

extension Light {
    init() {
        self.init(position: .zero,
                  direction: vector_float3(0, -1, 0),
                  type: .unused,
                  color: .one,
                  specularColor: .one,
                  intensity: 1,
                  attenuation: vector_float3(1, 0, 0),
                  angle: .pi,
                  coneAttenuation: 0)
    }
}

extension Material {
    init(diffuseColor: vector_float3 = .one,
         specularColor: vector_float3 = .one,
         ambiantOcclusion: vector_float3 = .zero,
         shininess: Float = 32,
         roughness: Float = 1,
         metallic: Float = 1,
         colorTextureTransform: matrix_float3x3 = .init(1),
         normalTextureTransform: matrix_float3x3 = .init(1)
         ) {
        
        self.init()
        self.diffuseColor = diffuseColor
        self.specularColor = specularColor
        self.ambiantOcclusion = ambiantOcclusion
        self.shininess = shininess
        self.roughness = roughness
        self.metallic = metallic
        self.colorTextureTransform = colorTextureTransform
        self.normalTextureTransform = normalTextureTransform
    }
}
