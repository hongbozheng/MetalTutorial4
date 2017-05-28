//
//  BufferProvider.swift
//  MetalSwift
//
//  Created by Danny on 5/28/17.
//  Copyright © 2017 Danny. All rights reserved.
//

import Foundation
import Metal

class BufferProvider:NSObject {
    let inflightBuffersCount :Int
    private var uniformsBuffers:[MTLBuffer]
    private var avaliableBufferIndex: Int = 0
    var avaliableResourceSemaphore : DispatchSemaphore
    
    init(device: MTLDevice, inflightBuffersCount:Int, sizeOfUniformsBufffer:Int) {
        self.inflightBuffersCount = inflightBuffersCount
        uniformsBuffers = [MTLBuffer]()
        
        for _  in 0...inflightBuffersCount - 1 {
            let uniformsBuffer = device.makeBuffer(length: sizeOfUniformsBufffer, options: [])
            uniformsBuffers.append(uniformsBuffer)
        }
        
        avaliableResourceSemaphore = DispatchSemaphore(value: inflightBuffersCount)
    }
    
    func nextUniformsBuffer(projectionMatrix:Matrix4, modelViewMatrix:Matrix4, light:Light) -> MTLBuffer{
        let buffer = uniformsBuffers[avaliableBufferIndex]
        let bufferPointer = buffer.contents()
        
        memcpy(bufferPointer, modelViewMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        memcpy(bufferPointer + MemoryLayout<Float>.size * Matrix4.numberOfElements(), projectionMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        memcpy(bufferPointer + 2*MemoryLayout<Float>.size * Matrix4.numberOfElements(), light.raw(), Light.size())
        avaliableBufferIndex += 1
        if avaliableBufferIndex == inflightBuffersCount {
            avaliableBufferIndex = 0
        }
        return buffer
    }
    
    //deinit simply does a little cleanup before object deletion. Without this, your app would crash when the semaphore is waiting and you’d deleted BufferProvider.
    deinit {
        for _ in 0...self.inflightBuffersCount{
            self.avaliableResourceSemaphore.signal()
        }
    }
}
