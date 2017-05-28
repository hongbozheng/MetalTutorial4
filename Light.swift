//
//  Light.swift
//  MetalSwift
//
//  Created by Danny on 5/28/17.
//  Copyright © 2017 Danny. All rights reserved.
//

import Foundation

struct Light {
    var color:(Float,Float,Float)
    var ambientIntensity:Float
    var direction:(Float, Float, Float)
    var diffuseIntensity:Float
    var shininess: Float
    var specularIntensity:Float
    static func size() -> Int {
        //The GPU operates with memory chunks 16 bytes in size.Even though you have 10 floats, the GPU is still allocating memory for 12 floats — which gives you a mismatch error.
        return MemoryLayout<Float>.size * 12
    }
    
    func raw() -> [Float] {
        let raw = [color.0, color.1, color.2, ambientIntensity,direction.0,direction.1,direction.2,diffuseIntensity,shininess,specularIntensity]
        return raw
    }
}
