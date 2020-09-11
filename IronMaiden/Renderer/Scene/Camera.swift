//
//  Camera.swift
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import Metal

protocol Camera {
    var matrix: simd_float4x4 { get }
}

struct ProjectionCamera: Camera {
    
    var fov: Float { didSet{updateMatrix()}}
    var nearZ: Float {didSet{updateMatrix()}}
    var farZ: Float {didSet{updateMatrix()}}
    var aspect: Float {didSet{updateMatrix()}}
    
    private(set) var matrix: simd_float4x4
    
    init(fov: Float = Float(70).degreesToRadians,
         nearZ: Float = 0.1,
         farZ: Float = 100.0,
         aspect: Float = 1.0) {
        self.fov = fov
        self.nearZ = nearZ
        self.farZ = farZ
        self.aspect = aspect
        self.matrix = .identity()
        self.matrix = calculMatrix()
    }
    
    mutating func updateMatrix() {
        self.matrix = calculMatrix()
    }
    
    func calculMatrix() -> simd_float4x4 {
        return simd_float4x4(projectionFov: self.fov,
                             near: self.nearZ,
                             far: self.farZ,
                             aspect: self.aspect)
    }
    
}
