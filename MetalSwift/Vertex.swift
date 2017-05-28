//
//  Vertex.swift
//  testMetalSwift
//
//  Created by Danny on 5/25/17.
//  Copyright © 2017 Danny. All rights reserved.
//

import Foundation
/**
 This is a structure to store the position and color of each vertex. floatBuffer() is a handy method that returns the vertex data as an array of Floats in strict order.
 */
struct Vertex{
    var x,y,z: Float
    var r,g,b,a: Float
    var s,t:Float
    var nX, nY, nZ : Float
    func floatBuffer() -> [Float] {
        return [x,y,z,r,g,b,a,s,t,nX,nY,nZ]
    }
}
