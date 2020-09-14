//
//  Transform.swift
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import simd

public struct Transform {
    
    var position: simd_float3 { didSet { self._matrix = nil } }
    var scale: simd_float3 { didSet { self._matrix = nil } }
    var rotation: simd_quatf { didSet { self._matrix = nil } }
    private var _matrix: simd_float4x4?
    
    var eulerAngles: simd_float3 {
        get {
            self.rotation.eulerAngles
        }
        set {
            self.rotation = simd_quatf(eulerAngles: newValue)
        }
    }
    
    init() {
        self.position = .zero
        self.scale = .one
        self.rotation = simd_quatf()
        self._matrix = nil
    }
    
    mutating func matrix() -> simd_float4x4 {
        let mat: simd_float4x4
        if let matrix = self._matrix {
            mat = matrix
        } else {
            mat = self.calculMatrix()
            self._matrix = mat
        }
        return mat
    }
    
    func calculMatrix() -> simd_float4x4 {
        return simd_float4x4(translation: self.position)
            * simd_float4x4(self.rotation)
            * simd_float4x4(scaling: self.scale)
    }
    
}

