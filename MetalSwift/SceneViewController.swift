//
//  SceneViewController.swift
//  MetalSwift
//
//  Created by Danny on 5/28/17.
//  Copyright © 2017 Danny. All rights reserved.
//

import UIKit

class SceneViewController: MetalViewController,MetalViewControllerDelegate {

    var objectToDraw:Cube!
    var worldModelMatrix:Matrix4!
    let panSensivity:Float = 5.0
    var lastPanLocation: CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        worldModelMatrix = Matrix4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -4)
        worldModelMatrix.rotateAroundX(Matrix4.degrees(toRad: 25), y: 0.0, z: 0.0)
        
        objectToDraw = Cube(device: device, commandQ: commandQueue)
        self.metalViewControllerDelegate = self
        
        setupGesture()
    }

    func renderObjects(drawable: CAMetalDrawable) {
        objectToDraw.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil)

    }
    func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        objectToDraw.updateWithDelta(delta: timeSinceLastUpdate)
    }
    
    //MARK: - GESTURE RELATED
    func setupGesture(){
        let pan = UIPanGestureRecognizer(target: self, action: #selector(SceneViewController.pan))
        self.view.addGestureRecognizer(pan)
    }
    
    func pan(panGesture:UIPanGestureRecognizer){
        if panGesture.state == UIGestureRecognizerState.changed{
            let pointInView = panGesture.location(in: self.view)
            let xDelta = Float((lastPanLocation.x - pointInView.x)/view.bounds.width) * panSensivity;
            let yDelta = Float((lastPanLocation.y - pointInView.y)/view.bounds.height) * panSensivity;

            objectToDraw.rotationY -= xDelta
            objectToDraw.rotationX -= yDelta
            lastPanLocation = pointInView
        }else if panGesture.state == UIGestureRecognizerState.began {
            lastPanLocation = panGesture.location(in: view)
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
