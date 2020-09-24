//
//  Renderer.swift
//  IronMaiden
//
//  Created by Vistory Group on 07/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    
    let view: MTKView
    weak var eventView: EventView!
    var device: MTLDevice! { self.view.device }
    
    var commandQueue: MTLCommandQueue!
    
    var scene: Scene!
    
    fileprivate func setupScene() {
        
        do {
            let meshNode = Node()
            meshNode.name = "ground"
            meshNode.transform.scale = [40, 40, 40]
            
            let assetUrl = Bundle.main.url(forResource: "ModelAssets.scnassets/plane",
                                           withExtension: "obj")!
            
            let mesh = try! ModelMesh(url: assetUrl)
            
            meshNode.add(renderable: mesh)
            
            let material = Material()
            material.diffuseColor = .one
            material.specularColor = .one
            material.shininess = 12
            material.colorTextureScale = float2(16, 16)
            material.textures.diffuse = try! Material.loadTexture(name: "barn-ground")
            mesh.setMaterial(material)
            
            scene.rootNode.add(childNode: meshNode)
        }
        
        do {
            let meshNode = Node()
            meshNode.name = "train"
            meshNode.transform.position.y = 1
            
            let assetUrl = Bundle.main.url(forResource: "ModelAssets.scnassets/train", withExtension: "obj")!
            let mesh = try! ModelMesh(url: assetUrl)
            meshNode.transform.position = [0, 1, 0]
            
            let material = Material()
            material.diffuseColor = [0.1, 0.1, 1]
            material.specularColor = [1, 0, 0]
            material.shininess = 32
            mesh.setMaterial(material)
            
            meshNode.add(renderable: mesh)
            
            scene.rootNode.add(childNode: meshNode)
        }
        
        do {
            let meshNode = Node()
            meshNode.name = "treefir"
            meshNode.transform.position = [1.4, 0, 0]
            
            let assetUrl = Bundle.main.url(forResource: "ModelAssets.scnassets/treefir", withExtension: "obj")!
            let mesh = try! ModelMesh(url: assetUrl)
            
            let material = Material()
            material.diffuseColor = [0.1, 1, 0.1]
            material.specularColor = [1, 1, 0.1]
            material.shininess = 8
            mesh.setMaterial(material)
            
            meshNode.add(renderable: mesh)
            
            scene.rootNode.add(childNode: meshNode)
        }
        
        do {
            let meshNode = Node()
            meshNode.name = "house"
            meshNode.transform.position = [-1, 0, 3]
            
            let assetUrl = Bundle.main.url(forResource: "ModelAssets.scnassets/lowpoly-house", withExtension: "obj")!
            let mesh = try! ModelMesh(url: assetUrl)
            meshNode.add(renderable: mesh)
            
            scene.rootNode.add(childNode: meshNode)
        }
        
        do {
            let meshNode = Node()
            meshNode.name = "cottage-house"
            meshNode.transform.position = [3.5, 0, 3]
            
            let assetUrl = Bundle.main.url(forResource: "ModelAssets.scnassets/cottage1", withExtension: "obj")!
            
            let mesh = try! ModelMesh(url: assetUrl, options: .generateTangent)
            
            meshNode.add(renderable: mesh)
            
            let cottageTexture = try! Material.loadTexture(name: "cottage-color")
            let cottageNormal = try! Material.loadTexture(name: "cottage-normal")
            mesh.submeshes.forEach {
                $0.material!.textures.diffuse = cottageTexture
                $0.material!.textures.normal = cottageNormal
            }
            
            scene.rootNode.add(childNode: meshNode)
        }
        
        do {
            let meshNode = Node()
            meshNode.name = "chest"
            meshNode.transform.position = [1, 0, 2]
            meshNode.transform.scale = [0.6, 0.6, 0.6]
            
            let assetUrl = Bundle.main.url(forResource: "ModelAssets.scnassets/chest", withExtension: "obj")!
            let mesh = try! ModelMesh(url: assetUrl, options: .generateTangent)
            
            let chestTextureDiffuse = try! Material.loadTexture(url:
                                                                Bundle.main.url(forResource: "ModelAssets.scnassets/chest-color",
                                                                                withExtension: "png")!)
            let chestTextureNormal = try! Material.loadTexture(url:
                                                                Bundle.main.url(forResource: "ModelAssets.scnassets/chest-normal",
                                                                                withExtension: "png")!)
            let chestTextureRoughness = try! Material.loadTexture(url:
                                                                    Bundle.main.url(forResource: "ModelAssets.scnassets/chest-roughness",
                                                                                    withExtension: "png")!)
            
            mesh.submeshes.forEach {
                $0.material!.textures.diffuse = chestTextureDiffuse
                $0.material!.textures.normal = chestTextureNormal
                $0.material!.textures.roughness = chestTextureRoughness
            }
            
            meshNode.add(renderable: mesh)
            
            scene.rootNode.add(childNode: meshNode)
        }
        
        do {
            let meshNode = Node()
            meshNode.name = "cube"
            meshNode.transform.scale = [0.6, 0.6, 0.6]
            meshNode.transform.position = [-1, 0.5, -1]
            
            let assetUrl = Bundle.main.url(forResource: "ModelAssets.scnassets/cube", withExtension: "obj")!
            
            let mesh = try! ModelMesh(url: assetUrl, options: .generateTangent)
            
            let cubeColor = try! Material.loadTexture(name: "cube-color")
            let cubeNormal = try! Material.loadTexture(name: "cube-normal")
            let cubeRoughness = try! Material.loadTexture(name: "cube-roughness")
            mesh.submeshes.forEach {
                $0.material!.textures.diffuse = cubeColor
                $0.material!.textures.normal = cubeNormal
                $0.material!.textures.roughness = cubeRoughness
            }
            
            meshNode.add(renderable: mesh)
            
            scene.rootNode.add(renderable: meshNode)
        }
        
        do {
            let cameraNode = Node()
            cameraNode.transform.position = float3(1, 2, -3)
            cameraNode.transform.rotation = simd_quatf(angle: 0.5, axis: [1, 0, 0])
            cameraNode.camera = ProjectionCamera()
            
            scene.cameraNode = cameraNode
        }
        
        do {
            var light = ShaderLight()
            light.type = .point
            light.color = [0.9, 0.9, 0.9]
            light.specularColor = [0.6, 0.6, 0.6]
            light.intensity = 0.3
            light.attenuation = [0.3, 0, 0]
            scene.frameLights.append(light)
        }
        
        do {
            var light = ShaderLight()
            light.type = .ambiant
            light.specularColor = [0.6, 0.6, 0.6]
            light.intensity = 0.1
            light.color = [1, 1, 1]
            scene.frameLights.append(light)
        }
        
    }
    
    init?(view: MTKView) {
        self.view = view
        super.init()
        
        if device == nil {
            return nil
        }
        
        view.depthStencilPixelFormat = .depth32Float
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        self.scene = Scene(device: device,
                           colorPixelFormat: self.view.colorPixelFormat)
        self.scene.aspectRatio = Float(view.frame.width / view.frame.height)
        
        setupScene()
        
        self.commandQueue = device.makeCommandQueue()!
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.scene.aspectRatio = Float(size.width / size.height)
        if let cameraNode = self.scene.cameraNode,
           let camera = cameraNode.camera as? ProjectionCamera {
            cameraNode.camera = ProjectionCamera(fov: camera.fov, nearZ: camera.nearZ, farZ: camera.farZ, aspect: self.scene.aspectRatio)
        }
    }
    
    var currentTime: TimeInterval = 0
    
    var rotationX: Float = 0
    var rotationY: Float = 0
    
    func draw(in view: MTKView) {
        self.currentTime += 1.0 / TimeInterval(view.preferredFramesPerSecond)
        self.scene.time.deltaTime = self.currentTime - self.scene.time.elapsedTime
        self.scene.time.elapsedTime = self.currentTime
        
        if let cameraNode = self.scene.cameraNode { // camera moving
            let kd = self.eventView.keysDown
            let mvSpd = 5.0 * Float(self.scene.time.deltaTime)
            let forwardMoving = mvSpd * (kd.contains(Keycode.w).float - kd.contains(Keycode.s).float)
            let rightMoving = mvSpd * (kd.contains(Keycode.d).float - kd.contains(Keycode.a).float)
            let upMoving = mvSpd * (kd.contains(Keycode.space).float - kd.contains(Keycode.shift).float)
            let moveVector = cameraNode.worldTransformMatrix * float4(rightMoving, upMoving, forwardMoving, 0)
            cameraNode.transform.position += moveVector.xyz
            
            let agSpd = 6.0 * Float(self.scene.time.deltaTime)
            let xRotation = agSpd * (kd.contains(Keycode.upArrow).float - kd.contains(Keycode.downArrow).float)
            let yRotation = agSpd * (kd.contains(Keycode.rightArrow).float - kd.contains(Keycode.leftArrow).float)
            
            rotationX += xRotation
            rotationY += yRotation
            
            cameraNode.transform.eulerAngles = simd_float3(rotationX, rotationY, 0)
        }
        
        if let cameraNode = scene.cameraNode {
            self.scene.frameLights[0].position = (cameraNode.worldTransformMatrix * float4(0, 0, 0, 1)).xyz
        }
        
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        self.scene.render(in: view, renderEncoder: renderEncoder)
        
        renderEncoder.endEncoding()
        
        let drawable = view.currentDrawable!
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        DispatchQueue.main.async {
            self.view.needsDisplay = true
        }
    }
    
}

extension Renderer: EventUIHandler {
    func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case Keycode.q:
            print("it's q")
        default:
            print("keyCode: \(event.keyCode)")
        }
        print("key downs: \(self.eventView.keysDown)")
    }
    
    func keyUp(with event: NSEvent) {
        print("key downs: \(self.eventView.keysDown)")
    }
    
    func mouseDown(with event: NSEvent) {
        print("mouse down at \(event.locationInWindow)")
    }
    
    func mouseUp(with event: NSEvent) {
        print("mouse up at \(event.locationInWindow)")
    }
}
