//
//  ContentView.swift
//  IronMaiden
//
//  Created by Vistory Group on 07/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

import SwiftUI
import MetalKit

struct MetalView: NSViewRepresentable {
    
    class Coordinator: NSObject {
        let view: MetalView
        let eventView: EventView = EventView()
        var renderer: Renderer?
        
        init(_ view: MetalView) {
            self.view = view
            super.init()
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        context.coordinator.renderer = Renderer(view: mtkView)
        mtkView.delegate = context.coordinator.renderer
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        
        mtkView.addSubview(context.coordinator.eventView)
        context.coordinator.eventView.delegate = context.coordinator.renderer
        context.coordinator.renderer?.eventView = context.coordinator.eventView
        
        DispatchQueue.main.async {
            mtkView.window?.makeFirstResponder(context.coordinator.eventView)
        }
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.eventView.frame.size = nsView.frame.size
    }
    
    
}

protocol EventUIHandler: class {
    func keyDown(with event: NSEvent)
    func keyUp(with event: NSEvent)
    func mouseDown(with event: NSEvent)
    func mouseUp(with event: NSEvent)
}

extension EventUIHandler {
    func keyDown(with event: NSEvent) {}
    func keyUp(with event: NSEvent) {}
    func mouseDown(with event: NSEvent) {}
    func mouseUp(with event: NSEvent) {}
}

class EventView: NSView {
    
    weak var delegate: EventUIHandler?
    
    var keysDown: Set<UInt16> = []
    var mouseLocation: CGPoint = .zero
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        self.keysDown.insert(event.keyCode)
        delegate?.keyDown(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        self.keysDown.remove(event.keyCode)
        delegate?.keyUp(with: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        self.mouseLocation = event.locationInWindow
        delegate?.mouseDown(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.mouseLocation = event.locationInWindow
        delegate?.mouseUp(with: event)
    }
    
}

struct ContentView: View {
    
    let mainMetalView = MetalView()
    
    var body: some View {
        ZStack {
            self.mainMetalView
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
