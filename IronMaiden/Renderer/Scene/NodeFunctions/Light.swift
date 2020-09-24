//
//  Light.swift
//  IronMaiden
//
//  Created by Giantwow on 21/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit

struct Light {
    var type: LightType = .unused
    var color: vector_float3 = .one
    var specularColor: vector_float3 = .one
    var intensity: Float = 1
    var attenuation: vector_float3 = [1, 0, 0]
    var angle: Float = .pi
    var coneAttenuation: Float = 0
}

extension Node {
    func shaderLight(modelMatrix: matrix_float4x4) -> ShaderLight? {
        guard let light = self.light else {
            return nil
        }
        let position = modelMatrix * simd_float4(0, 0, 0, 1)
        let direction = modelMatrix * simd_float4(0, 0, -1, 0)
        return ShaderLight(position: position.xyz, direction: direction.xyz, type: light.type, color: light.color, specularColor: light.specularColor, intensity: light.intensity, attenuation: light.attenuation, angle: light.angle, coneAttenuation: light.coneAttenuation)
    }
}
