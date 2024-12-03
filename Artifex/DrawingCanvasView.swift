//
//  DrawingCanvasView.swift
//  Artifex
//
//  Created by Jesus Alejandro on 11/30/24.
//

import Foundation

import SwiftUI

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var lines: [[CGPoint]]
    
    class Coordinator: NSObject {
        var metalView: MetalView
        
        init(_ metalView: MetalView) {
            self.metalView = metalView
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let point = gesture.location(in: metalView)
            switch gesture.state {
            case .began:
                metalView.beginLine(at: point)
            case .changed:
                metalView.addPointToLine(point)
            case .ended, .cancelled:
                metalView.endLine()
            default:
                break
            }
        }
    }
    
    func makeUIView(context: Context) -> MetalView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device.")
        }
        
        let metalView = MetalView(frame: .zero, device: device)
        metalView.backgroundColor = UIColor.white
        metalView.isOpaque = false

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan))
        panGesture.maximumNumberOfTouches = 1
        metalView.addGestureRecognizer(panGesture)

        metalView.setLines(lines)
        context.coordinator.metalView = metalView
        return metalView
    }
    
    func updateUIView(_ uiView: MetalView, context: Context) {
        uiView.setLines(lines)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(MetalView(frame: .zero, device: MTLCreateSystemDefaultDevice()!))
    }
}
