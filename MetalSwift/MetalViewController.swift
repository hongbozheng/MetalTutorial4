//
//  MetalViewController.swift
//  MetalSwift
//
//  Created by Danny on 5/28/17.
//  Copyright © 2017 Danny. All rights reserved.
//

//https://www.raywenderlich.com/146420/metal-tutorial-swift-3-part-4-lighting
/**
 In this fourth part of the series, you’ll learn how to add some lighting to the cube. As you work through this tutorial, you’ll learn:
 Some basic light concepts
 Phong light model components
 How to calculate light effect for each point in the scene, using shaders
 */
import UIKit
import Metal

protocol MetalViewControllerDelegate: class {
    func updateLogic(timeSinceLastUpdate:CFTimeInterval)
    func renderObjects(drawable:CAMetalDrawable)

}
class MetalViewController: UIViewController {

    var device:MTLDevice!
    var metalLayer: CAMetalLayer!
    
    var pipelineState : MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer:CADisplayLink!
    var projectionMatrix:Matrix4!
    var lastFrameTimestamp: CFTimeInterval = 0.0
    
    weak var metalViewControllerDelegate:MetalViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        device = MTLCreateSystemDefaultDevice()
        projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)

        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
//        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)

        
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary?.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary?.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        commandQueue = device.makeCommandQueue()
        
        timer = CADisplayLink(target: self, selector: #selector(MetalViewController.newFrame(displayLink:)))
        timer.add(to: RunLoop.main, forMode: .defaultRunLoopMode)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let window = view.window{
            let scale = window.screen.nativeScale
            let layerSize = view.bounds.size
            
            view.contentScaleFactor = scale
            metalLayer.frame = CGRect(x: 0, y: 0, width: layerSize.width, height: layerSize.height)
            metalLayer.drawableSize = CGSize(width: layerSize.width * scale, height: layerSize.height * scale)
        }
    }

    func render() {
        guard let drawable = metalLayer?.nextDrawable() else {return}
      self.metalViewControllerDelegate?.renderObjects(drawable: drawable)
    }
    
    func newFrame(displayLink:CADisplayLink) {
        if lastFrameTimestamp == 0.0{
            lastFrameTimestamp = displayLink.timestamp
        }
        
        let elapsed : CFTimeInterval = displayLink.timestamp - lastFrameTimestamp
        lastFrameTimestamp = displayLink.timestamp
        
        gameloop(timeSinceLastUpdate: elapsed)
    }
    
    func gameloop(timeSinceLastUpdate:CFTimeInterval) {
        self.metalViewControllerDelegate?.updateLogic(timeSinceLastUpdate: timeSinceLastUpdate)
        autoreleasepool{
            self.render()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
