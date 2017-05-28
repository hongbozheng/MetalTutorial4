//
//  Node.swift
//  testMetalSwift
//
//  Created by Danny on 5/25/17.
//  Copyright © 2017 Danny. All rights reserved.
//

import Foundation
import Metal
import QuartzCore

class Node {
    let device: MTLDevice
    let name : String
    var vertexCount: Int
    var vertexBuffer: MTLBuffer
    
    var positionX:Float = 0.0
    var positionY: Float = 0.0
    var positionZ: Float = 0.0
    
    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    var scale: Float     = 1.0
    
    var time:CFTimeInterval = 0.0
    var bufferProvider:BufferProvider
    var texture: MTLTexture
    lazy var samplerState: MTLSamplerState? = Node.defaultSampler(device:self.device)
    
    let light = Light(color:(1.0,1.0,1.0),ambientIntensity:0.1,direction:(0.0,0.0,1.0),diffuseIntensity:0.8,shininess:10,specularIntensity:2)
    
    init(name:String, vertices:Array<Vertex>,device:MTLDevice,texture:MTLTexture){
        var vertexData = Array<Float>()
        for vertex in vertices{
            vertexData += vertex.floatBuffer()
        }
    
    let dataSize = vertexData.count * MemoryLayout.size(ofValue:vertexData[0])
    vertexBuffer = device.makeBuffer(bytes:vertexData,length:dataSize,options:[])
    
    self.name = name
    self.device = device
    vertexCount = vertices.count
    self.texture = texture
        
        let sizeOfUniformBuffer = MemoryLayout<Float>.size * Matrix4.numberOfElements() * 2 + Light.size()
        self.bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBufffer: sizeOfUniformBuffer)
        
    }
    
    
    func render(commandQueue:MTLCommandQueue,pipelineState:MTLRenderPipelineState,drawable:CAMetalDrawable,parentModelViewMatrix:Matrix4,projectionMatrix:Matrix4,clearColor:MTLClearColor?){
    
        //make the CPU wait in case bufferProvider.avaliableResourcesSemaphore has no free resources.
        _ = bufferProvider.avaliableResourceSemaphore.wait(timeout: DispatchTime.distantFuture)

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        //Why hasn’t the background changed? The answer for that is simple: The vertex shader runs on all scene geometry, but the background is not geometry. In fact, it’s not even a background, it’s just a constant color which the GPU uses for places where nothing is drawn.
        renderPassDescriptor.colorAttachments[0].clearColor =     MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
       
        // Think of this as the list of render commands that you wish to execute for this frame.
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // signal the semaphore when the resource becomes available.
        commandBuffer.addCompletedHandler { (_) in
            self.bufferProvider.avaliableResourceSemaphore.signal()
        }
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        renderEncoder.setFragmentTexture(texture, at: 0)
        if let samplerState = samplerState{
            renderEncoder.setFragmentSamplerState(samplerState, at: 0)
        }
        renderEncoder.setCullMode(MTLCullMode.front)
        let nodeModelMatrix = self.modelMatrix()
        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
        
//        //Ask the device to create a buffer with shared CPU/GPU memory. This method is called 60 times per second, and you create a new buffer each time it’s called. This is a performance issue
//        let uniformBuffer = device.makeBuffer(length: MemoryLayout<Float>.size * Matrix4.numberOfElements()*2, options: [])
//        //Get a raw pointer from buffer (similar to void * in Objective-C).
//        let bufferPointer = uniformBuffer.contents()
//        //Copy your matrix data into the buffer.
//        memcpy(bufferPointer, nodeModelMatrix.raw(), MemoryLayout<Float>.size*Matrix4.numberOfElements())
//        memcpy(bufferPointer + MemoryLayout<Float>.size * Matrix4.numberOfElements(), projectionMatrix.raw(),  MemoryLayout<Float>.size * Matrix4.numberOfElements())
        
        let uniformBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix: projectionMatrix, modelViewMatrix: nodeModelMatrix,light:light)
        
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount,instanceCount:vertexCount/3)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
    
    func modelMatrix() -> Matrix4 {
        let matrix = Matrix4()
        matrix.translate(positionX,y:positionY,z:positionZ)
        matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
        matrix.scale(scale, y: scale, z: scale)
        return matrix
    }
    
    func updateWithDelta(delta:CFTimeInterval) {
        time += delta
    }
    
    class func defaultSampler(device:MTLDevice) -> MTLSamplerState {
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter = MTLSamplerMinMagFilter.nearest
        sampler.magFilter = MTLSamplerMinMagFilter.nearest
        sampler.mipFilter = MTLSamplerMipFilter.nearest
        sampler.maxAnisotropy         = 1
        sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp           = 0
        sampler.lodMaxClamp           = FLT_MAX
        return device.makeSamplerState(descriptor: sampler)
    }

}

