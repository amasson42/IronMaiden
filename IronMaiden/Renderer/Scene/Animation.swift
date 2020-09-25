//
//  Animation.swift
//  IronMaiden
//
//  Created by Vistory Group on 25/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit
import SwiftUI


protocol LinearAnimatable {
    static func linearValue(_ lhs: Self, _ rhs: Self, _ t: TimeInterval) -> Self
}

extension Float: LinearAnimatable {
    static func linearValue(_ lhs: Float, _ rhs: Float, _ t: TimeInterval) -> Float {
        return ((rhs - lhs) * Float(t) + lhs)
    }
}

extension float3: LinearAnimatable {
    static func linearValue(_ lhs: SIMD3<Float>, _ rhs: SIMD3<Float>, _ t: TimeInterval) -> SIMD3<Float> {
        return float3(.linearValue(lhs.x, rhs.x, t),
                      .linearValue(lhs.y, rhs.y, t),
                      .linearValue(lhs.z, rhs.z, t))
    }
}

extension simd_quatf: LinearAnimatable {
    static func linearValue(_ lhs: simd_quatf, _ rhs: simd_quatf, _ t: TimeInterval) -> simd_quatf {
        return simd_quatf(ix: .linearValue(lhs.imag.x, rhs.imag.x, t),
                          iy: .linearValue(lhs.imag.y, rhs.imag.y, t),
                          iz: .linearValue(lhs.imag.z, rhs.imag.z, t),
                          r: .linearValue(lhs.real, rhs.real, t))
    }
}

struct FramePosition: LinearAnimatable {
    var position: float3 = .zero
    var scale: float3 = .one
    var rotation: simd_quatf = simd_quatf()
    
    static func linearValue(_ lhs: FramePosition, _ rhs: FramePosition, _ t: TimeInterval) -> FramePosition {
        return FramePosition(position: .linearValue(lhs.position, rhs.position, t),
                             scale: .linearValue(lhs.scale, rhs.scale, t),
                             rotation: .linearValue(lhs.rotation, rhs.rotation, t))
    }
}

class Keyframes {
    private(set) var positions: [(time: TimeInterval, position: FramePosition)] = []
    
    func addPosition(at time: TimeInterval, position: FramePosition) {
        guard self.positions.isEmpty == false else {
            self.positions = [(time, position)]
            return
        }
        for i in self.positions.indices {
            if self.positions[i].time > time {
                self.positions.insert((time, position), at: i)
            }
        }
    }
    
    func position(at time: TimeInterval) -> FramePosition {
        guard let firstFrame = positions.first else {
            return FramePosition()
        }
        
        if time < firstFrame.time {
            return firstFrame.position
        }
        
        var previousFrame = firstFrame
        let positions = self.positions.dropFirst()
        for i in positions.indices {
            
            if positions[i].time > time {
                let t = (time - previousFrame.time)
                    / (positions[i].time - previousFrame.time)
                return FramePosition.linearValue(previousFrame.position,
                                                 positions[i].position,
                                                 t)
            }
            
            previousFrame = positions[i]
        }
        
        return positions.last!.position
    }
}


