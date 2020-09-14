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
    init() {
        self.init(diffuseColor: [1, 1, 1],
                  shininess: 32,
                  specularColor: [1, 1, 1],
                  diffuseTextureTransform: .init(diagonal: .one),
                  normalTextureTransform: .init(diagonal: .one))
        
    }
}
